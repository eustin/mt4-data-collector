#property version   "1.00"
#property strict
#property indicator_chart_window

// inputs
input int SLICE_WINDOW_BARS = 15;
input bool GET_ALL_BARS = False;
input int REFRESH_PERIOD_MINS = 15;

// globals
int csv_file;
string latest_date = "0";
string symbols[];
int num_symbols;
int time_periods[] = {1, 5, 15, 30, 60, 240, 1440, 10080, 43200};
static bool got_all_bars = False;
static datetime previous_bar_time;

// functions ----------------------------------------------------------------------------

bool file_empty(int csv_file) {
   return(FileSize(csv_file) <= 5);
}

void write_csv_header(int csv_file_handle) {
   FileWrite(csv_file_handle, "symbol", "period", "time", "open", "high", "low", "close", 
   "tick_volume", "spread", "real_volume"); 
}

string file_timestamp() {
   string file_time = TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES|TIME_SECONDS);
   StringReplace(file_time, " ", "_");
   StringReplace(file_time, ":", "-");
   return (file_time); 
}

string make_file_name() {
   string file_name;
   file_name = Symbol() + "_" + Period() + "_" + file_timestamp() + "_" + MathRand() + ".csv";
   return(file_name);
}


bool is_multiple_of_fifteen() {
   int current_minute = TimeMinute(TimeLocal());
   return(MathMod(current_minute, 15) == 0); 
}

int make_file_handle() {
   string file_name = make_file_name();
   Print("making file named  " + file_name);
   int file_handle = FileOpen(file_name, FILE_WRITE|FILE_CSV, ',');
   return(file_handle);
}

int get_num_bars() {
   int num_bars;
   if (GET_ALL_BARS & !got_all_bars) {
      num_bars = iBars(NULL, Period()) - 1;
   } else {
      num_bars = SLICE_WINDOW_BARS;
   }
   Print("Num bars is " + num_bars);
   return(num_bars);
}

void write_csv_lines(int csv_file, MqlRates &rates[], int num_bars) {
   for (int i = 0; i < num_bars; i++) {
      FileWrite(
         csv_file, 
         Symbol(), Period(), rates[i].time, rates[i].open, rates[i].high, rates[i].low,
         rates[i].close, rates[i].tick_volume, rates[i].spread, rates[i].real_volume
      );
   }
   Print("Successfully wrote " + num_bars + " bars");
}

void process_time_slice(int csv_file) {
   MqlRates rates[];
   ArraySetAsSeries(rates,true);

   int num_bars = get_num_bars();   
   int rate_slice = CopyRates(Symbol(), PERIOD_CURRENT, 1, num_bars, rates);
   write_csv_lines(csv_file, rates, num_bars);
}

int write_files() {
   long curr_chart_id = ChartID();
   // write files for all time frames
   for (int i=0; i < 9; i++) {
      ChartSetSymbolPeriod(curr_chart_id, NULL, time_periods[i]);

      Print("Opening file handle...");
      string file_name = make_file_name();
      int csv_file = make_file_handle();

      if (csv_file == INVALID_HANDLE)  {
         Print("file handle invalid! returning...");
         return(0);
      }
      write_csv_header(csv_file);
      process_time_slice(csv_file);
      FileClose(csv_file);
   }
   got_all_bars = True;
   return(0);
}

int get_symbols() {
   // inspired by 7bit and sxTed's Symbols.mqh
   string symbol_name;
   string symbol_file_name = "symbols_"+AccountServer()+".csv";

   int symbols_handle=FileOpenHistory("symbols.raw", FILE_BIN|FILE_READ);
   num_symbols = FileSize(symbols_handle) / 1936;
   ArrayResize(symbols, num_symbols);
  
   for (int i=0; i  < num_symbols; i++) {
      symbol_name = FileReadString(symbols_handle, 12);
      symbols[i] = symbol_name;
      FileSeek(symbols_handle, 1924, SEEK_CUR);
   }
   return(0);   
}

void wait_seconds(int seconds) {
   datetime curr_time = TimeLocal();
   while(TimeLocal() < curr_time + seconds) {
   }
}


// inspired by Tadas Talaikis, TALAIKIS.COM
bool check_new_bar(int period_mins) {
   if (previous_bar_time != iTime(NULL, period_mins, 0)) {
      previous_bar_time = iTime(NULL, period_mins, 0);
      return(True);
   } else {
      return(False);
   }
}

// main ---------------------------------------------------------------------------------

int OnInit() {

   get_symbols();
   RefreshRates();
   ChartSetInteger(ChartID(), CHART_AUTOSCROLL, True);
   return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {

   long current_chart_id = ChartID();
   //Alert(got_all_bars);
   if (check_new_bar(REFRESH_PERIOD_MINS)) {
      write_files();
   }
   
   

   //for (int i=0; i < 2; i++) {
   //   ChartSetSymbolPeriod(current_chart_id, symbols[i], 0);
   //   write_files();
   // }
   return(0);

                
}

void OnDeinit(const int reason) {  
   
}
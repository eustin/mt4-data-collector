#property version   "1.00"
#property strict
#property indicator_chart_window

// inputs
input bool GET_ALL_BARS = True;
input int REFRESH_PERIOD_MINS = 240;

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
   "tick_volume"); 
}

string file_timestamp() {
   string file_time = TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES|TIME_SECONDS);
   StringReplace(file_time, " ", "_");
   StringReplace(file_time, ":", "-");
   return (file_time); 
}

string make_file_name(int period) {
   string file_name;
   file_name = Symbol() + "_" + period + "_" + file_timestamp() + "_" + MathRand() + ".csv";
   return(file_name);
}


int make_file_handle(int curr_period) {
   string file_name = make_file_name(curr_period);
   Print("making file named  " + file_name);
   int file_handle = FileOpen(file_name, FILE_WRITE|FILE_CSV, ',');
   return(file_handle);
}


int get_num_bars(int curr_period) {
   int num_bars;
   if (GET_ALL_BARS & !got_all_bars) {
      num_bars = iBars(NULL, curr_period) - 1;
   } else {
      if (curr_period == 1) {
         num_bars = 240;
      } else if (curr_period == 240) {
         num_bars = 1;      
      } else {
         num_bars = curr_period;
      }
   }
   Print("Num bars is " + num_bars);
   return(num_bars);
}


string time_to_string(datetime rate_date) {
   string date_string = TimeToStr(rate_date, TIME_DATE|TIME_SECONDS);
   StringReplace(date_string, ".", "-");
   return(date_string);
}


void write_csv_lines(int csv_file, int curr_period, MqlRates &rates[], int num_bars) {
   for (int i = 0; i < num_bars; i++) {
      FileWrite(
         csv_file, 
         Symbol(), curr_period, time_to_string(rates[i].time), rates[i].open, rates[i].high,
          rates[i].low, rates[i].close, rates[i].tick_volume
      );
   }
   Print("Successfully wrote " + num_bars + " bars");
}


void process_time_slice(int csv_file, int curr_period) {
   MqlRates rates[];
   ArraySetAsSeries(rates,true);

   int num_bars = get_num_bars(curr_period);   
   int rate_slice = CopyRates(Symbol(), curr_period, 1, num_bars, rates);
   write_csv_lines(csv_file, curr_period, rates, num_bars);
}


int get_period_data(int period_to_get) {
   Print("Opening file handle...");
   string file_name = make_file_name(period_to_get);
   int csv_file = make_file_handle(period_to_get);
   if (csv_file == INVALID_HANDLE)  {
      Print("file handle invalid! returning...");
      return(-1);
   }
   write_csv_header(csv_file);
   process_time_slice(csv_file, period_to_get);
   FileClose(csv_file);
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
   get_period_data(1);
   get_period_data(240);
   got_all_bars = True;
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
   
   if (check_new_bar(240)) {      
      get_period_data(1);      
      get_period_data(240);
   } 
   
   return(0);
}

void OnDeinit(const int reason) {  
   
}
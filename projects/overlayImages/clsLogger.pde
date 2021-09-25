import java.util.Date;
import java.text.DateFormat;
import java.text.SimpleDateFormat;

static int logLevel = LogLevel.INFO;

static abstract class LogLevel {
  static final int FATAL = 0;
  static final int ERROR = 1;
  static final int WARN = 2;
  static final int INFO = 3;
  static final int FINE = 4;
  static final int FINER = 5;
  static final int FINEST = 6;
}

static class Logger {
  static void fatal(String msg) {
    log(msg, LogLevel.FATAL);
  } 

  static void warn(String msg) {
    log(msg, LogLevel.WARN);
  } 

  static void error(String msg) {
    log(msg, LogLevel.ERROR);
  } 

  static void info(String msg) {
    log(msg, LogLevel.INFO);
  } 

  static void fine(String msg) {
    log(msg, LogLevel.FINE);
  } 

  static void finer(String msg) {
    log(msg, LogLevel.FINER);
  } 

  static void finest(String msg) {
    log(msg, LogLevel.FINEST);
  } 

  static void log(String msg, int thisLogLevel) {
    if (thisLogLevel <= logLevel) {
      println(msg + " - " + timeStamp());
    }
  }

  static String timeStamp() {
    DateFormat formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    Date d = new Date();
    String ts = formatter.format(d);
    return ts;
  }
}

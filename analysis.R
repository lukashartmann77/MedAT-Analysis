# ---------------------------------------------------------------------------- #
# Author:      Lukas Hartmann
# Date:        26.04.2025
# File:        medat_analysis.R
# Description: Analysis of MEDAT simulation performance
# ---------------------------------------------------------------------------- #

# Load data -------------------------------------------------------------------

data <- read.csv("data.csv")

# Data cleaning ---------------------------------------------------------------

for (col in names(data)) {
  if (is.character(data[[col]])) {
    data[[col]] <- gsub(" ", "", data[[col]])
  }
}

data$points_per <- data$points / data$quest * 100

data$date <- as.Date(data$date)
data$type <- as.factor(data$type)
data$task <- as.factor(data$task)
data$cat  <- as.factor(data$cat)

data <- data[order(data$date), ]

# Aggregate daily performance per task ----------------------------------------

data <- aggregate(
  points_per ~ date + task,
  data = data,
  FUN = mean
)

# Rolling mean function -------------------------------------------------------

data_rolling_mean <- function(x, window = 5) {
  
  if (length(x) < window) {
    return(rep(NA, length(x)))
  }
  
  if (window %% 2 == 1) {
    n <- floor(window / 2)
    weights <- c(seq(1, n + 1), seq(n, 1))
  } else {
    n <- window / 2
    weights <- c(seq(1, n), seq(n, 1))
  }
  
  weights <- weights / sum(weights)
  
  pad_left <- rev(head(x, n))
  pad_right <- rev(tail(x, n))
  
  x_padded <- c(pad_left, x, pad_right)
  result <- stats::filter(x_padded, weights, sides = 2)
  
  result_trimmed <- result[(n + 1):(length(result) - n)]
  
  return(as.numeric(result_trimmed))
}

# Generate analysis plots -----------------------------------------------------

plot_task_analysis <- function(df, task_label, xlim_right = NULL) {
  
  if (nrow(df) == 0) {
    return(NULL)
  }
  
  df$datetime <- as.POSIXct(df$date)
  
  xlim_vals <- if (!is.null(xlim_right)) {
    c(min(df$datetime), as.POSIXct(xlim_right))
  } else {
    range(df$datetime)
  }
  
  model <- lm(points_per ~ datetime, data = df)
  
  layout(matrix(c(
    1, 1, 1, 2,
    3, 4, 5, 6,
    7, 7, 8, 8
  ), nrow = 3, byrow = TRUE))
  
  par(mar = c(4, 4.5, 2.5, 1.5))
  par(oma = c(0, 0, 4, 0))
  
  # Raw performance plot ------------------------------------------------------
  
  plot(
    df$datetime,
    df$points_per,
    type = "b",
    lwd = 2,
    col = "black",
    ylim = c(0, 100),
    xlab = "Date",
    ylab = "Performance (%)",
    main = "Raw Performance",
    xlim = xlim_vals
  )
  
  abline(h = 90, col = "red", lty = 3)
  abline(model, lty = 2)
  
  if (!is.null(xlim_right)) {
    abline(v = as.POSIXct(xlim_right), col = "blue", lty = 3)
  }
  
  grid()
  
  mtext(
    paste("Analysis:", toupper(task_label)),
    side = 3,
    outer = TRUE,
    line = 1.5,
    cex = 1.5,
    font = 2
  )
  
  # Histogram ---------------------------------------------------------------
  
  hist(
    df$points_per,
    breaks = 10,
    col = "lightblue",
    border = "white",
    main = "Performance Distribution",
    xlab = "Performance (%)",
    xlim = c(0, 100)
  )
  
  abline(v = 90, col = "red", lty = 3)
  grid()
  
  # Rolling trend plots -----------------------------------------------------
  
  n <- length(df$points_per)
  
  if (n >= 5) {
    
    max_window <- n - 1
    
    if (max_window %% 2 == 0) {
      max_window <- max_window - 1
    }
    
    max_window <- max(max_window, 3)
    
    make_odd <- function(x) {
      x <- floor(x)
      if (x %% 2 == 0) x <- x + 1
      max(x, 3)
    }
    
    windows <- unique(c(
      make_odd(max_window / 3),
      make_odd((2 * max_window) / 3),
      max_window
    ))
    
    for (window in windows) {
      
      trend <- data_rolling_mean(
        df$points_per,
        window = window
      )
      
      plot(
        df$datetime,
        df$points_per,
        type = "l",
        col = "grey80",
        lty = 2,
        ylim = c(0, 100),
        xlab = "Date",
        ylab = "Performance (%)",
        main = paste("Trend (Window =", window, ")"),
        xlim = xlim_vals
      )
      
      lines(
        df$datetime,
        trend,
        col = "black",
        lwd = 2
      )
      
      abline(h = 90, col = "red", lty = 3)
      grid()
    }
    
  } else {
    
    for (i in 1:3) {
      plot(
        df$datetime,
        df$points_per,
        type = "l",
        col = "grey80",
        lty = 2,
        ylim = c(0, 100),
        xlab = "Date",
        ylab = "Performance (%)",
        main = "Not enough data for trend analysis",
        xlim = xlim_vals
      )
      
      abline(h = 90, col = "red", lty = 3)
      grid()
    }
  }
  
  # Monthly boxplot ---------------------------------------------------------
  
  df$month <- format(df$date, "%Y-%m")
  
  boxplot(
    points_per ~ month,
    data = df,
    main = "Monthly Performance",
    xlab = "Month",
    ylab = "Performance (%)",
    ylim = c(0, 100),
    las = 2,
    col = "lightgreen"
  )
  
  abline(h = 90, col = "red", lty = 3)
  grid()
  
  # Cumulative mean ---------------------------------------------------------
  
  cumulative_mean <- cumsum(df$points_per) / seq_along(df$points_per)
  
  plot(
    df$datetime,
    cumulative_mean,
    type = "l",
    col = "darkgreen",
    lwd = 2,
    ylim = c(0, 100),
    main = "Cumulative Mean",
    xlab = "Date",
    ylab = "Performance (%)"
  )
  
  abline(h = 90, col = "red", lty = 3)
  grid()
  
  # Goal deviation ----------------------------------------------------------
  
  delta <- df$points_per - 90
  
  plot(
    df$datetime,
    delta,
    type = "h",
    col = ifelse(delta >= 0, "darkgreen", "indianred"),
    main = "Distance from Goal",
    xlab = "Date",
    ylab = "Difference (%)"
  )
  
  abline(h = 0, lty = 2)
  grid()
  
  cat("Task", task_label, "completed.\n")
}

# Task list -------------------------------------------------------------------

tasks <- c(
  "bi", "ch", "ph", "ma",
  "tv",
  "fz", "gm", "zf", "wf", "ie",
  "ee", "er", "se"
)

pdf(
  "analysis.pdf",
  width = 12,
  height = 12,
  onefile = TRUE
)

exam_date <- "2025-07-04"

for (task_name in tasks) {
  
  task_data <- subset(
    data,
    task == task_name
  )
  
  plot_task_analysis(
    task_data,
    task_name,
    xlim_right = exam_date
  )
}

invisible(dev.off())

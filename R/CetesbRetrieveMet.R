#' Download meteorological parameters from CETESB QUALAR
#'
#' This function download the main meteorological parameters for
#' model evaluation from one air quality station (AQS) of CETESB AQS network.
#' It will pad out the date with missing data with NA.
#'
#'
#' @param username User name of CETESB QUALAR
#' @param password User name's password of CETESB QUALAR
#' @param aqs_code Code of AQS
#' @param start_date Date to start downloading in dd/mm/yyyy
#' @param end_date Date to end downloading in dd/mm/yyyy
#' @param verbose Print query summary
#' @param to_csv  Creates a csv file. FALSE by default
#'
#' @return data.frame wth Temperature (C), Relative Humidity (%), Wind Speed (m/s) and Direction (degrees),
#' and Pressure information.
#' @export
#'
#' @examples
#' \dontrun{
#' # Downloading meteorological data from Pinheiros AQS
#' # from January first to 7th of 2020
#' my_user_name <- "John Doe"
#' my_pass_word <- "drowssap"
#' pin_code <- 99 # Check with cetesb_aqs
#' start_date <- "01/01/2020"
#' end_date <- "07/01/2020"
#'
#' pin_pol <- CetesbRetrieveMet(my_user_name, my_pass_word, pin_code, start_date, end_date)
#' }
CetesbRetrieveMet <-  function(username, password,
                               aqs_code, start_date,
                               end_date, verbose = TRUE,
                               to_csv = FALSE){

  aqs <- cetesb

  # Check if aqs_code is valid
  if (is.numeric(aqs_code) & aqs_code %in% aqs$code){
    aqs_code <- aqs_code
    aqs_name <- aqs$name[aqs$code == aqs_code]
  } else if (is.character(aqs_code) & aqs_code %in% (aqs$name)){      # nocov start
    aqs_name <- aqs_code
    aqs_code <- aqs$code[aqs$name == aqs_code]
  } else {
    stop("Wrong aqs_code value, please check cetesb_latlon or cetesb_aqs",
         call. = FALSE)
  }                                                                   # nocov end

  # Adding query summary
  if (verbose){
    cat("Your query is:\n")
    cat("Parameter: TC, RH, WS, WD, Pressure \n")
    cat("Air quality staion:", aqs_name, "\n")
    cat("Period: From", start_date, "to", end_date, "\n")
  }

  tc <- CetesbRetrieve(username, password, 25,
                       aqs_code, start_date,
                       end_date, verbose = FALSE)

  rh <- CetesbRetrieve(username, password, 28,
                       aqs_code, start_date,
                       end_date, verbose = FALSE)

  ws <- CetesbRetrieve(username, password, 24,
                       aqs_code, start_date,
                       end_date, verbose = FALSE)

  wd <- CetesbRetrieve(username, password, 23,
                       aqs_code, start_date,
                       end_date, verbose = FALSE)

  p <- CetesbRetrieve(username, password, 29,
                      aqs_code, start_date,
                      end_date, verbose = FALSE)

  all_met <- data.frame(date = tc$date,
                        tc = tc$pol,
                        rh = rh$pol,
                        ws = ws$pol,
                        wd = wd$pol,
                        p = p$pol,
                        aqs = tc$aqs,
                        stringsAsFactors = F)
  cat(paste(
    "Download complete for", unique(all_met$aqs), "\n"
    ))

  if (to_csv){
    file_name <- paste0(aqs_name, "_", "MET_",                          # nocov start
                        gsub("/", "-", start_date), "_",
                        gsub("/", "-", end_date), ".csv")
    utils::write.table(all_met, file_name, sep = ",", row.names = F )

    file_path <- paste(getwd(), file_name, sep = "/")
    cat(paste(file_path, "was created"), "\n")                              # nocov end
  }

  return(all_met)
}

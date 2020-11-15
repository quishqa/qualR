#' Download air quality and meteorology information from MonitorAr-Rio
#'
#' This function download air quality and meteorology measurements from MonitorAr-Rio
#' program from Rio de Janeiro city.
#'
#' @param start_date Date to start downloading in dd/mm/yyyy
#' @param end_date Date to end downloading in dd/mm/yyyy
#' @param aqs_code AQS code
#' @param param Paremeter to download. It can be a vector with many parameters.
#' @param to_local Date information in local time. TRUE by default.
#' @param to_csv Creates a csv file. FALSE by default
#'
#' @return data.frame with the selected parameter information
#' @export
#'
#' @examples
#' \dontrun{
#' # Downloading Ozone information from Centro AQS
#' # from February of 2019
#' date_start <- "01/02/2019"
#' date_end <- "01/03/2019"
#' aqs_code <- "CA"
#' param <- "O3"
#' ca_o3 <- MonitorArRetrieve(date_start, date_end, aqs_code, param)
#'
#' }
MonitorArRetrieve <- function(start_date, end_date, aqs_code, param, to_local=TRUE, to_csv=FALSE){

  start_date_format <- as.POSIXct(strptime(start_date, format="%d/%m/%Y"), tz = "UTC")
  end_date_format <-  as.POSIXct(strptime(end_date, format="%d/%m/%Y"), tz = "UTC")

  # Function to create the WHERE query
  where_query <- function(ds, de, aqs){
    ds_format <- format(ds, format="%Y-%m-%d %H:%M:%S")
    de_format <- format(de, format="%Y-%m-%d %H:%M:%S")
    date_range <- paste0("Data >= TIMESTAMP'", ds_format, "' AND ",
                         "Data <= TIMESTAMP'", de_format)
    aqs <- paste0("' AND Esta", iconv("\u00e7\u00e3", "", "utf-8", "byte"),
                  "o = '", aqs, "'")
    where <- paste0(date_range, aqs)
    return(where)
  }

  where <- where_query(start_date_format, end_date_format, aqs_code)

  # Creating outFiled
  if (length(param) == 1){
    outfields <- paste("Data", param, sep = ",")
  } else {
    outfields <- paste("Data", paste(param, collapse = ","), sep = ",")
  }

  url <- "https://services1.arcgis.com/OlP4dGNtIcnD3RYf/arcgis/rest/services/Qualidade_do_ar_dados_horarios_2011_2018/FeatureServer/2/query?"

  res <- httr::GET(url,
                   query = list(
                     where = where_query(start_date_format, end_date_format, aqs_code),
                     outFields = outfields,
                     f = 'json'
                   ))
  # Checking request
  if (res$status_code == 200){
    print("Succesful request")
    print(paste("Downloading ", paste(param, collapse = " ")))
  } else {
    print("Something goes wrong")
  }
  # print(res$status)
  raw_data <- jsonlite::fromJSON(rawToChar(res$content))
  data_aqs <- raw_data$features[[1]]

  # Changing epoch to human redable date
  data_aqs$Data <- as.POSIXct(data_aqs$Data/1000,  origin = "1970-01-01", tz = "UTC")

  # Check completition
  start_date2 <- paste(as.character(as.Date(start_date_format)), "00:30")
  end_date2 <- paste(as.character(as.Date(end_date_format) - 1), "23:30")

  all_dates <- data.frame(
    Data = seq(as.POSIXct(strptime(start_date2, format="%Y-%m-%d %H:%M"), tz = "UTC"),
               as.POSIXct(strptime(end_date2, format="%Y-%m-%d %H:%M"), tz = "UTC"),
               by = "hour")
  )

  if (nrow(all_dates) != nrow(data_aqs)){
    print("Padding out missing dates with NA")
    data_aqs <- merge(all_dates, data_aqs, all = TRUE)
  }

  # Adding aqs code to dataframe

  data_aqs$aqs <- aqs_code

  # Changing to local time
  if (to_local){
    attributes(data_aqs$Data)$tzone <- "America/Sao_Paulo"
  }

  # Changing Data column name to date
  colnames(data_aqs)[1] <- "date"
  if (to_csv){
    file_name <- paste0(aqs_code, "_",
                        paste(param, collapse = "-"), "_",
                        gsub("/", "-", start_date), "_",
                        gsub("/", "-", end_date), ".csv")
    utils::write.table(data_aqs, file_name, sep = ",", row.names = F)
    file_path <- paste(getwd(), file_name, sep = "/")
    print(paste(file_path, "was created"))
  }

  return(data_aqs)

}
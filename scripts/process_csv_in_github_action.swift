import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

enum column : Int, CaseIterable {
    case timestamp               = 0 // A
    case provider                = 1 // B
    case regioncity              = 2 // C
    case currenturl              = 3 // D
    case updatednewsourceurl     = 4 // E
    case datatype                = 5 // F
    case request                 = 6 // G
    case downloadurl             = 7 // H
    case country                 = 8 // I
    case subdivision_name        = 9 // J
    case municipality            = 10 // K
    case name                    = 11 // L
    case yournameorg             = 12 // M
    case license_url             = 13 // N
    case tripupdatesurl          = 14 // O
    case servicealertsurl        = 15 // P
    case genunknownrturl         = 16 // Q
    case authentication_type     = 17 // R
    case authentication_info_url = 18 // S
    case api_key_parameter_name  = 19 // T
    case note                    = 20 // U
    case gtfsschedulefeatures    = 21 // W
    case gtfsschedulestatus      = 22 // Y
    case gtfsrealtimestatus      = 23 // Z
    case youremail               = 24 // AA
    case dataproduceremail       = 25 // AB
    case realtimefeatures        = 26 // AC
    case isocountrycode          = 27 // AB
    case feedupdatestatus        = 28 // AC
}

enum defaults: String {
    case date = "01/01/1970"
}

enum requestType: String {
    case isAddNewFeed = "New source"
    case isUpdateExistingFeed = "Source update"
    case isToRemoveFeed = "removed"
}

enum dataType: String {
    case schedule = "Schedule"
    case realtime = "Realtime"
}

enum realtimeDataType: String {
    case vehiclePositions = "Vehicle Positions"
    case tripUpdates = "Trip Updates"
    case serviceAlerts = "Service Alerts"
    case unknown = "general / unknown"
}

enum realtimeDataTypeCode: String {
    case vehiclePositions = "vp"
    case tripUpdates = "tu"
    case serviceAlerts = "sa"
    case unknown = "gu"
}

let arguments : [String] = CommandLine.arguments

if CommandLine.argc == 5 {

    let csvLineSeparator     : String = "\n"
    let csvColumnSeparator   : String = ","

    let csvURLStringArg      : String = arguments[1] // the first argument [0] is the name of the script, we can ignore in this context.
    let dateToFind           : String = arguments[2]
    let dateFormatGREPArg    : String = arguments[3]
    let dateFormatDesiredArg : String = arguments[4]

    guard let csvURLasURL : URL = URL(string: csvURLStringArg) else {
        print("\n   ERROR: The specified URL does not appear to exist :\n   \(csvURLStringArg)\n")
        exit(1)
    }
    
    let dateFormatter : DateFormatter = DateFormatter() //; let today : Date = Date()
    dateFormatter.dateFormat = dateFormatDesiredArg
    // let todayDate : String = dateFormatter.string(from: today) // Ex.: 07/27/2023

    let csvData : String = try String(contentsOf: csvURLasURL, encoding:.utf8)

    let csvLines : [String] = csvData.components(separatedBy: csvLineSeparator) ; var csvArray : [[String]] = [[]]
    for currentLine : String in csvLines {
        csvArray.append(currentLine.components(separatedBy: csvColumnSeparator))
    }
    
    var PYTHON_SCRIPT_OUTPUT : String = ""
    let dateFormatAsRegex : Regex<AnyRegexOutput> = try Regex(dateFormatGREPArg)

    for line : [String] in csvArray {
        
        var PYTHON_SCRIPT_ARGS_TEMP : String = ""

        if line.count >= column.allCases.count {

            let timestamp               : String = line[column.timestamp.rawValue].trimmingCharacters(in: .whitespacesAndNewlines)
            let provider                : String = line[column.provider.rawValue]
            let datatype                : String = line[column.datatype.rawValue]
            let request                 : String = line[column.request.rawValue]
            let country                 : String = line[column.country.rawValue]
            let subdivision_name        : String = line[column.subdivision_name.rawValue]
            let municipality            : String = line[column.municipality.rawValue]
            let name                    : String = line[column.name.rawValue]
            let license_url             : String = line[column.license_url.rawValue]
            let downloadURL             : String = line[column.downloadurl.rawValue]
            let updatednewsourceurl     : String = line[column.updatednewsourceurl.rawValue]
            let authentication_type     : String = line[column.authentication_type.rawValue]
            let authentication_info_url : String = line[column.authentication_info_url.rawValue]
            let api_key_parameter_name  : String = line[column.api_key_parameter_name.rawValue]
            let note                    : String = line[column.note.rawValue]
            let gtfsschedulefeatures    : String = line[column.gtfsschedulefeatures.rawValue]
            let gtfsschedulestatus      : String = line[column.gtfsschedulestatus.rawValue]
            let gtfsrealtimestatus      : String = line[column.gtfsrealtimestatus.rawValue]
            let realtimefeatures        : String = line[column.realtimefeatures.rawValue]

            

            let dateFromCurrentLine : String = extractDate(from: timestamp, usingGREP: dateFormatAsRegex, desiredDateFormat: dateFormatDesiredArg)
            
            if dateFromCurrentLine == dateToFind { // ...the row has been added on the date we're looking for, process it.
                
                if request.contains(requestType.isAddNewFeed.rawValue) { // add new feed
                    
                    if datatype.contains(dataType.schedule.rawValue) { // add_gtfs_schedule_source
                        
                        PYTHON_SCRIPT_ARGS_TEMP = "add_gtfs_schedule_source(provider=\(provider), country_code=\(country), direct_download_url=\(updatednewsourceurl.isEmpty ? downloadURL : updatednewsourceurl), authentication_type=\(authentication_type), authentication_info_url=\(authentication_info_url), api_key_parameter_name=\(api_key_parameter_name), subdivision_name=\(subdivision_name), municipality=\(municipality), license_url=\(license_url), name=\(name), status=\(gtfsschedulestatus), features=\(gtfsschedulefeatures))"
                        
                    } else if datatype.contains(dataType.realtime.rawValue) { // add_gtfs_realtime_source
                        // Emma: entity_type matches the realtime Data type options of Vehicle Positions, Trip Updates, or Service Alerts. If one of those three are selected, add it. If not, omit it.
                        
                        let realtimecode : String = realtimeCode(for:datatype)
                        PYTHON_SCRIPT_ARGS_TEMP = "add_gtfs_realtime_source(entity_type=\(realtimecode), provider=\(provider), direct_download_url=\(downloadURL.isEmpty ? updatednewsourceurl : downloadURL), authentication_type=\(authentication_type), authentication_info_url=\(authentication_info_url), api_key_parameter_name=\(api_key_parameter_name), license_url=\(license_url), name=\(name), static_reference=\"TO_BE_PROVIDED\", note=\(note), status=\(gtfsrealtimestatus), features=\(realtimefeatures))"
                        
                    }
                    
                } else if request.contains(requestType.isUpdateExistingFeed.rawValue) { // update existing feed
                    
                    if datatype.contains(dataType.schedule.rawValue) { // update_gtfs_schedule_source
                        
                        PYTHON_SCRIPT_ARGS_TEMP = "update_gtfs_schedule_source(mdb_source_id=\"\", provider=\(provider), name=\(name), country_code=\(country), subdivision_name=\(subdivision_name), municipality=\(municipality), direct_download_url=\(updatednewsourceurl.isEmpty ? downloadURL : updatednewsourceurl), authentication_type=\(authentication_type), authentication_info_url=\(authentication_info_url), api_key_parameter_name=\(api_key_parameter_name), license_url=\(license_url), status=\(gtfsschedulestatus), features=\(gtfsschedulefeatures))"
                        
                    } else if datatype.contains(dataType.realtime.rawValue) { // update_gtfs_realtime_source
                    
                        let realtimecode : String = realtimeCode(for:datatype)
                        PYTHON_SCRIPT_ARGS_TEMP = "update_gtfs_realtime_source(mdb_source_id=\"\", entity_type=\(realtimecode), provider=\(provider), direct_download_url=\(downloadURL.isEmpty ? updatednewsourceurl : downloadURL), authentication_type=\(authentication_type), authentication_info_url=\(authentication_info_url), api_key_parameter_name=\(api_key_parameter_name), license_url=\(license_url), name=\(name), static_reference=\"TO_BE_PROVIDED\", note=\(note), status=\(gtfsrealtimestatus), features=\(realtimefeatures))"
                    }
                    
                }  else if request.contains(requestType.isToRemoveFeed.rawValue) { // remove feed
                    
                    if datatype.contains(dataType.schedule.rawValue) { // update_gtfs_schedule_source
                        
                        PYTHON_SCRIPT_ARGS_TEMP = "update_gtfs_schedule_source(mdb_source_id=\"\", provider=\(provider), name=\"**** Requested for removal ****\", country_code=\(country), subdivision_name=\(subdivision_name), municipality=\(municipality), direct_download_url=\(updatednewsourceurl.isEmpty ? downloadURL : updatednewsourceurl), authentication_type=\(authentication_type), authentication_info_url=\(authentication_info_url), api_key_parameter_name=\(api_key_parameter_name), license_url=\(license_url), status=\(gtfsschedulestatus), features=\(gtfsschedulefeatures))"
                        
                    } else if datatype.contains(dataType.realtime.rawValue) { // update_gtfs_realtime_source

                        let realtimecode : String = realtimeCode(for:datatype)
                        PYTHON_SCRIPT_ARGS_TEMP = "update_gtfs_realtime_source(mdb_source_id=\"\", entity_type=\"[\(realtimecode)]\", provider=\(provider), direct_download_url=\(downloadURL.isEmpty ? updatednewsourceurl : downloadURL), authentication_type=\(authentication_type), authentication_info_url=\(authentication_info_url), api_key_parameter_name=\(api_key_parameter_name), license_url=\(license_url), name=\"**** Requested for removal ****\", static_reference=\"TO_BE_PROVIDED\", note=\(note), status=\(gtfsrealtimestatus), features=\(realtimefeatures))"
                        
                    }
                    
                } else { // ... assume this is a new feed by default :: add_gtfs_schedule_source

                    if datatype.contains(dataType.schedule.rawValue) { // update_gtfs_schedule_source
                        
                        PYTHON_SCRIPT_ARGS_TEMP = "add_gtfs_schedule_source(provider=\(provider), country_code=\(country), direct_download_url=\(updatednewsourceurl.isEmpty ? downloadURL : updatednewsourceurl), authentication_type=\(authentication_type), authentication_info_url=\(authentication_info_url), api_key_parameter_name=\(api_key_parameter_name), subdivision_name=\(subdivision_name), municipality=\(municipality), license_url=\(license_url), name=\(name), status=\(gtfsschedulestatus), features=\(gtfsschedulefeatures))"
                        
                    } else if datatype.contains(dataType.realtime.rawValue) { // update_gtfs_realtime_source

                        let realtimecode : String = realtimeCode(for:datatype)
                        PYTHON_SCRIPT_ARGS_TEMP = "add_gtfs_realtime_source(entity_type=\(realtimecode), provider=\(provider), direct_download_url=\(downloadURL.isEmpty ? updatednewsourceurl : downloadURL), authentication_type=\(authentication_type), authentication_info_url=\(authentication_info_url), api_key_parameter_name=\(api_key_parameter_name), license_url=\(license_url), name=\(name), static_reference=\"TO_BE_PROVIDED\", note=\(note), status=\(gtfsrealtimestatus), features=\(realtimefeatures))"
                        
                    }
                }
                
            }
            
        } // END of the row has been added today, process it.
        
        if PYTHON_SCRIPT_ARGS_TEMP.count > 0 { PYTHON_SCRIPT_OUTPUT = ( PYTHON_SCRIPT_OUTPUT + "§" + PYTHON_SCRIPT_ARGS_TEMP ) }

    } // END FOR LOOP

    // return final output so the action can grab it and pass it on to the Python script.
    print(PYTHON_SCRIPT_OUTPUT.dropFirst())

} else {
    print("Incorrect number of arguments provided to the script. Expected 3: a string with the URL, a date format and the date format desired.")
    exit(1)
}

// MARK: - FUNCTIONS

func extractDate(from theDateToConvert: String, usingGREP dateFormatAsGREP: Regex<AnyRegexOutput>, desiredDateFormat desiredFormat: String) -> String {
    if let match : Regex<Regex<AnyRegexOutput>.RegexOutput>.Match = theDateToConvert.firstMatch(of: dateFormatAsGREP) { 
        // find first match
        let matchOutput : String = String(match.output[0].substring!)

        // date formatter and find date
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = desiredFormat
        let date : Date? = dateFormatter.date(from: matchOutput)
        
        // default date if formatter fails, otherwise return correctly formatted date
        var returnDate : String = defaults.date.rawValue
        if date != nil { returnDate = dateFormatter.string(from: date!) }
        return returnDate
    }
    
    // return default date
    return defaults.date.rawValue
}

func realtimeCode(for theDataType: String) -> String {
    if theDataType.contains(realtimeDataType.vehiclePositions.rawValue) { return realtimeDataTypeCode.vehiclePositions.rawValue }
    if theDataType.contains(realtimeDataType.tripUpdates.rawValue) { return realtimeDataTypeCode.tripUpdates.rawValue }
    if theDataType.contains(realtimeDataType.serviceAlerts.rawValue) { return realtimeDataTypeCode.serviceAlerts.rawValue }
    return realtimeDataTypeCode.unknown.rawValue
}
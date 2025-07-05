//
//  PhotoExif.swift
//  Photo Annotate
//
//  Created by Brett Larson on 4/16/25.
//
//*************************************************************************************************
//* Copyright Brett Larson 2025
//*
//* This program is free software: you can redistribute it and/or modify it under the terms of the
//* GNU General Public License version 3 as published by the Free Software Foundation,
//*
//* This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
//* without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
//* PURPOSE. See the GNU General Public License for more details.
//*
//* You should have received a copy of the GNU General Public License along with this program. If
//* not, see <https://www.gnu.org/licenses/>.
//*************************************************************************************************

import Foundation
import AppKit
import CoreLocation


/**
 Class to extract some metadata from an image.
 */
class ImageExifExtract {
    var location: CLLocationCoordinate2D?
    var direction: Double?
    var datetime: String
        
    /**
     Initialize ImageExifExtractor
     
     - Parameter imageUrl: the URL of the image file.
     
     Discussion: If available in image sets location, direction, datetime.
     */
    init(imageUrl: URL) {
        location = nil
        direction = nil
        datetime = ""
        if let cgImageSource = CGImageSourceCreateWithURL(imageUrl as CFURL, nil) {
            if let imageProperties = CGImageSourceCopyPropertiesAtIndex(cgImageSource, 0, nil) as Dictionary? {
                if let gpsData = imageProperties[kCGImagePropertyGPSDictionary] as! [CFString: Any]? {
                    
                    // Extract photo lat,lon
                    // My Nikon W300 can have GPS EXIF data without any of the following
                    // so we need to check that everything needed exists.
                    if  let latVal = gpsData[kCGImagePropertyGPSLatitude],
                        let latRef = gpsData[kCGImagePropertyGPSLatitudeRef],
                        let lonVal = gpsData[kCGImagePropertyGPSLongitude],
                        let lonRef = gpsData[kCGImagePropertyGPSLongitudeRef] {
                        // Latitude
                        var lat = latVal as! Double
                        let refNS = latRef as! String
                        if (refNS == "S") {
                            lat *= -1.0
                        }
                        // Longitude
                        var lon = lonVal as! Double
                        let refEW = lonRef as! String
                        if (refEW == "W") {
                            lon *= -1.0
                        }
                        //print("   (\(lat), \(lon))")
                        location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    }
                    
                    // Extract photo direction.
                    if let direction_raw = gpsData[kCGImagePropertyGPSImgDirection] as? Double {
                        // let directionRef = gpsData[kCGImagePropertyGPSImgDirectionRef]
                        // Not used.  Should be 'T' for True or 'M' for Magnetic.
                        direction = direction_raw
                    }
                }
                
                // Extract photo date.
                if let exifData = imageProperties[kCGImagePropertyExifDictionary] as! [CFString: Any]? {
                    if  let datetime_raw = exifData[kCGImagePropertyExifDateTimeDigitized] {
                        //print("datetime = \(datetime)")
                        datetime = (datetime_raw as! String)
                    }
                }
            }
        }
    }
}


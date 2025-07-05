//
//  PhotoModel.swift
//  Photo Annotate
//
//  Created by Brett Larson on 4/15/25.
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

import SwiftUI
import Foundation
import AppKit
import CoreLocation
import MapKit

/**
 Opens a dialog to select a folder with images.
 
  - Returns: The folder URL or nil.
 */
@MainActor func selectFolderDialog() -> URL? {
    let openPanel = NSOpenPanel();
    openPanel.title = "Select a folder with images"
    openPanel.message = "Select folder with images to annotate"
    openPanel.canChooseDirectories = true;
    openPanel.canChooseFiles = false;
    openPanel.allowsMultipleSelection = false;
    openPanel.canCreateDirectories = false;
    openPanel.delegate = nil;
    
    let dialogResult = openPanel.runModal()
    if (dialogResult == .OK) {
        if let result = openPanel.url {
            return result
        }
    }
    return nil
}


/**
 Compare function for sorting URL's by absolute string.
 
 - Parameter url1: first URL
 - Parameter url2: second URL
 
 - Returns: True if url1.absoluteString < url2.absoluteString.
 */
func ascendingUrlCompare(url1: URL, url2: URL) -> Bool {
    let s1 = url1.absoluteString
    let s2 = url2.absoluteString
    return (s1 < s2)
}


/**
 A class model for Photo Annotate.
 */
@Observable class PhotoAnnotateModel {
    let textHistoryLimit = 200
    let defaultPickerText = "(Prior Text)"
    let defaultMapLocation = CLLocationCoordinate2D(latitude: 45.0, longitude: -90.0)
    let defaultMapSpan = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    let pasteboard : NSPasteboard = NSPasteboard.general

    var photoPathnames: [URL]
    var currentPhotoIndex: Int
    var currentPhotoNumber: Int // Cannot use computed value because used with TextField() edit.
    var photoCount: Int
    var currentImage: NSImage?
    var currentPhotoPath: String
    var currentPhotoText: String
    var currentPhotoDate: String
    var currentPhotoLatLonString: String
    var currentPhotoDirection: Double?
    var currentPhotoLocation: CLLocationCoordinate2D?
    var editorPhotoText: String
    var pickerSelectedText: String
    var priorSavedTexts: [String]
    var pickerFilterText: String
    var pickerTextList: [String]
    var photoTextChanged: Bool
    var mapPosition: MapCameraPosition
    var mapSpan: MKCoordinateSpan
    var nextDisabled: Bool
    var prevDisabled: Bool
    
    /**
     Initialize a PhotoAnnotateModel.
     */
    init() {
        photoPathnames = []
        currentPhotoIndex = 0
        currentPhotoNumber = 0
        photoCount = 0
        currentPhotoPath = ""
        currentPhotoText = ""
        pickerFilterText = ""
        priorSavedTexts = []
        editorPhotoText = ""
        pickerFilterText = ""
        pickerSelectedText = defaultPickerText
        pickerTextList =  [defaultPickerText]
        photoTextChanged = false
        currentImage = nil
        if let defaultImage = NSImage(named: "defaultPhoto") {
            currentImage = defaultImage
        }
        currentPhotoDate = ""
        currentPhotoLatLonString = ""
        currentPhotoDirection = nil
        currentPhotoLocation = nil
        mapSpan = defaultMapSpan
        mapPosition = MapCameraPosition.region(MKCoordinateRegion(center: defaultMapLocation, span: defaultMapSpan))
        nextDisabled = true
        prevDisabled = true
    }
    
    /**
     Updates the next and prev button disable state.
     */
    func updatePhotoNavigationButtonDisables() {
        nextDisabled = (currentPhotoIndex >= photoCount-1)
        prevDisabled = (currentPhotoIndex <= 0)
    }
    
    /**
     Opens a dialog to select a folder with photos.
     
        If the folder is valid all image pathnames with lowercase extension "jpg", "jpeg", "png" and "heic" within that
        folder are added to self.photoPathnames.  After the last path is added self.photoPathnames is sorted, photoCount
        updated and updatePhotoInfo() called.
     */
    @MainActor func selectFolder() {
        let photosFolder = selectFolderDialog()
        if let folder = photosFolder {
            let fm = FileManager.default
            do {
                // Build list of image files matching extensions.
                photoPathnames = []
                currentPhotoIndex = 0
                currentPhotoNumber = currentPhotoIndex + 1
                photoCount = 0
                let folderEntries = try fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
                for folderEntry in folderEntries {
                    let fileExt = folderEntry.pathExtension.lowercased()
                    if (fileExt == "jpg") || (fileExt == "jpeg") || (fileExt == "png") || (fileExt == "heic") {
                        photoPathnames.append(folderEntry)
                        //print("Added:", folderEntry)
                    }
                }
                photoCount = photoPathnames.count
                photoPathnames.sort(by: ascendingUrlCompare)
                //print("photoCount:", photoCount)
                updatePhotoInfo()
            } catch {
            }
        }
    }
    
    /**
     Update info for selected image
     
        Sets currentPhotoPath to the current currently selected image.  Calls readPhotoText() to read any existing
     photo text.  Attempts to extract metadata from the image setting currentPhotoLatLonString, currentPhotoLocation, mapPosition, currentPhotoDirection
     and currentPhotoDate.
     */
    func updatePhotoInfo() {
        if photoCount > 0 {
            currentImage = NSImage(byReferencing: photoPathnames[currentPhotoIndex])
            if currentImage != nil {
                let imageExifExtract = ImageExifExtract(imageUrl: photoPathnames[currentPhotoIndex])
                if let location = imageExifExtract.location {
                    currentPhotoLatLonString = String(format: "%11.6f, %11.6f", location.latitude, location.longitude)
                    currentPhotoLocation = location
                    mapPosition = MapCameraPosition.region(
                        MKCoordinateRegion(
                            center: location,
                            span: mapSpan
                        )
                    )
                } else {
                    currentPhotoLatLonString = ""
                    currentPhotoLocation = nil
                    // Leave mapPosition at last location.
                }
                currentPhotoDirection = imageExifExtract.direction
                currentPhotoDate = imageExifExtract.datetime
            } else {
                print("Error, nil image:", photoPathnames[currentPhotoIndex])
            }
            currentPhotoPath = photoPathnames[currentPhotoIndex].path
            readPhotoText()
        }
        updatePhotoNavigationButtonDisables()
    }
    
    /**
     Read text from data file associated with image.
     
        Attempts to read text data from a file having same basename as image with ".txt" extension setting currentPhotoText and
     editorPhotoText.  If no text file is found currentPhotoText is initialized to "".  Resets photoTextChanged to fales.
     */
    func readPhotoText() {
        let pathWithoutExtension = photoPathnames[currentPhotoIndex].deletingPathExtension()
        let textPath = pathWithoutExtension.appendingPathExtension("txt")
        //print("textPath:", textPath)
        let fm = FileManager.default
            if fm.fileExists(atPath: textPath.path) {
            do {
                currentPhotoText = try String.init(contentsOfFile: textPath.path, encoding: String.Encoding.utf8)
            } catch {
                currentPhotoText = ""
            }
        } else {
            currentPhotoText = ""
        }
        editorPhotoText = currentPhotoText
        photoTextChanged = false
    }
    
    /**
     Callback function for Picker() change.
     
        Sets editorPhotoText to picker selected text.  Updates photoTextChanged by comparing editorPhotoText to
     currentPhotoText.
     */
    func pickerTextChange() {
        if pickerSelectedText != defaultPickerText {
            if pickerSelectedText != editorPhotoText {
                editorPhotoText = pickerSelectedText
                if editorPhotoText != currentPhotoText {
                    photoTextChanged = true
                } else {
                    photoTextChanged = false
                }
            }
        }
    }
    
    /**
     Callback function for TextEditor() change.
     
        Updates photoTextChanged by comparing editorPhotoText to currentPhotoText.
     */
    func editorTextChange() {
        if editorPhotoText != currentPhotoText {
            photoTextChanged = true
        } else {
            photoTextChanged = false
        }
    }
    
    /**
     Callback function for Picker Filter change..
     
        Updates photoTextChanged by comparing editorPhotoText to currentPhotoText.
     */
    func updatePickerList() {
        // Insert special first value so user must select another value.
        // Without this selecting first value does not generate change event.
        pickerTextList =  [defaultPickerText]
        
        // Add values from priorSaveTexts based on filter.
        if pickerFilterText == "" {
            pickerTextList += priorSavedTexts
        } else {
            for text in priorSavedTexts {
                if text.lowercased().contains(pickerFilterText.lowercased()) {
                    pickerTextList += [text]
                }
            }
        }
        
        // Select first element in list.
        pickerSelectedText = pickerTextList[0]
    }
    
    /**
     Callback function for user map change.
     
        Captures the current map span.
     */
    func updateMapSpan(region: MKCoordinateRegion?) {
        if let region = region {
            mapSpan = region.span
//            print("updateMapSpan() = \(mapSpan)")
        }
    }

    /**
     Action for next image button.
     
        First calls checkIfTextSaved().  Then increments currentPhotoIndex with limiting, updates currentPhotoNumber and
     calls updatePhotoNavigationButtonDisables().
     */
    @MainActor func nextImage() {
        checkIfTextSaved()
        if (currentPhotoIndex + 1) >= photoCount {
            currentPhotoIndex = photoCount - 1
        } else {
            currentPhotoIndex += 1
            updatePhotoInfo()
        }
        currentPhotoNumber = currentPhotoIndex+1
        updatePhotoNavigationButtonDisables()
    }
    
    /**
     Action for next image button.
     
        First calls checkIfTextSaved().  Then decrements currentPhotoIndex with limiting, updates currentPhotoNumber and
     calls updatePhotoNavigationButtonDisables().
     */
    @MainActor func previousImage() {
        checkIfTextSaved()
        if currentPhotoIndex <= 0 {
            currentPhotoIndex = 0
        } else {
            currentPhotoIndex -= 1
            updatePhotoInfo()
        }
        currentPhotoNumber = currentPhotoIndex+1
        updatePhotoNavigationButtonDisables()
    }
    
    /**
     Callback for photo sequence TextField().
     
        If the entered photo sequence number is in range sets currentPhotoIndex.  Otherwise sets currentPhotoNumber
     based on currentPhotoIndex.  Finally calls updatePhotoInfo().
     */
    func validateIndexEdit() {
        if (currentPhotoNumber > 0) && (currentPhotoNumber <= photoCount) {
            currentPhotoIndex = currentPhotoNumber - 1
        } else {
            currentPhotoNumber = currentPhotoIndex + 1
        }
        updatePhotoInfo()
    }
    
    /**
     Check if photo text has changed but not been saved.
     
        If photo text has changed but not been saved display and alert to either Save or Discard the changes.
     */
    @MainActor func checkIfTextSaved() {
        if photoTextChanged == true {
            let alert = NSAlert()
            alert.messageText = "Text changes not saved."
            alert.informativeText = "This is informative text."
            alert.alertStyle = NSAlert.Style.warning
            alert.addButton(withTitle:"Discard")
            alert.addButton(withTitle:"Save")
            let res = alert.runModal()
            if res == NSApplication.ModalResponse.alertSecondButtonReturn {
                saveCurrentText()
            } else {
                photoTextChanged = false
            }
        }
    }
    
    /**
     Save the current photo text.
     
     Updates the priorSavedTexts list first removing any equal text from the list and then inserting the text at index = 1.
     The text at index = 0 is special and should not change (workaround for how the picker behaves if the value does not change).
     Then saves the text to a file with the same basename as the image but with ".txt" extension.
     */
    func saveCurrentText() {
        // This should only be called if the Save button is enabled because photoTextChange == true.
        
        // If text is already in list remove it.
        if let idx = priorSavedTexts.firstIndex(of: editorPhotoText) {
            priorSavedTexts.remove(at: idx)
        }
        
        // Add text to first in list.
        priorSavedTexts.insert(editorPhotoText, at: 0)
        
        // Limit text history length.
        while priorSavedTexts.count > textHistoryLimit {
            priorSavedTexts.remove(at: textHistoryLimit)
        }
        
        // Update state.
        currentPhotoText = editorPhotoText
        updatePickerList()

        // Build path to text file associated with photo.
        let pathWithoutExtension = photoPathnames[currentPhotoIndex].deletingPathExtension()
        let textPath = pathWithoutExtension.appendingPathExtension("txt")
        
        // Write data to file.
        if let data = currentPhotoText.data(using: .utf8) {
            do {
                let options = Data.WritingOptions.atomic
                try data.write(to: textPath, options: options)
                //print("Wrote photo text to: ", textPath)
                photoTextChanged = false
            } catch {
                print()
                print("Caught exception while writing notes to:", textPath)
                print("Error info: \(error)")
            }
        }
        
    }
    
    /**
     Callback for Copy Lat/Lon button.
     
        Clears the current pasteboard and they sets the pasteboard to self.photoLatLongString.
     */
    func copyLatLon() {
        pasteboard.clearContents()
        let success = pasteboard.setString(currentPhotoLatLonString, forType: NSPasteboard.PasteboardType.string)
        if (!success) {
            print("Error setting NSPastboard")
        }
    }
    
}

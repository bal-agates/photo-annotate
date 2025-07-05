//
//  ContentView.swift
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
import SplitView
import Foundation
import MapKit


struct ContentView: View {
    @State private var photosModel = PhotoAnnotateModel()
    @State private var mapStyleIndex = 0
    let mapStyles = [MapStyle.standard(), MapStyle.imagery(), MapStyle.hybrid()]
    @State private var imageScale = 1.0
    @State private var splitFraction = 0.5
    
    var body: some View {
        VStack {
            HSplit(left: {
                VStack {
                    GeometryReader { geometry in
                        ScrollView([.horizontal, .vertical]) {
                            if let image = photosModel.currentImage {
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .border(.black)
                                    .frame(width: geometry.size.width * imageScale,
                                           height: geometry.size.height * imageScale)
                            }
                        }
                        .defaultScrollAnchor(.center)
                    }
                    HStack {
                        Button {
                            imageScale *= 1.5
                        } label: {
                            Image(systemName: "plus.magnifyingglass")
                        }
                        Button {
                            imageScale /= 1.5
                        } label: {
                            Image(systemName: "minus.magnifyingglass")
                        }
                        Button {
                            imageScale = 1.0
                        } label: {
                            Image(systemName: "1.magnifyingglass")
                        }
                        Text("Zoom: " + String(format: "%5.2f", imageScale))
                    }
                }
                .padding()
            }, right: {
                VStack {
                    Map(position: $photosModel.mapPosition) {
                        if photosModel.currentPhotoLocation != nil {
                            Marker("photo", systemImage: "photo", coordinate: photosModel.currentPhotoLocation!)
                        }
                    }
                    .mapStyle(mapStyles[mapStyleIndex])
                    .onMapCameraChange { mapCameraUpdateContext in
//                        print("mapCameraChange: \(mapCameraUpdateContext.region)")
                        photosModel.updateMapSpan(region: mapCameraUpdateContext.region)
                    }
                    HStack {
                        Spacer()
                        Picker("", selection: $mapStyleIndex) {
                            Text("Standard").tag(0)
                            Text("Imagery").tag(1)
                            Text("Hybrid").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .fixedSize()
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Text("Date:")
                        Text(photosModel.currentPhotoDate)
                        Spacer()
                    }
                    HStack {
                        Text("LatLon:")
                        Text(photosModel.currentPhotoLatLonString)
                        Spacer()
                        Button(action: photosModel.copyLatLon) {
                            Text("Copy LatLon")
                        }
                    }
                    HStack {
                        Text("Direction:")
                        if photosModel.currentPhotoDirection != nil {
                            Text(String(format: "%6.2f", photosModel.currentPhotoDirection!))
                            Image(systemName: "arrowshape.up.fill")
                                .rotationEffect(Angle(degrees: photosModel.currentPhotoDirection!))
                        }
                        Spacer()
                    }
                }
                .padding()
            }
            )
            .fraction(splitFraction)
            .onDrag { fraction in
                splitFraction = fraction
                //print(fraction)
            }
            VStack {
                HStack {
                    Text("Notes Filter:")
                    TextField("Filter", text: $photosModel.pickerFilterText)
                        .onChange(of: photosModel.pickerFilterText) {
                            photosModel.updatePickerList()
                        }
                    Spacer()
                }
                Picker("Notes:", selection: $photosModel.pickerSelectedText) {
                    ForEach(photosModel.pickerTextList, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: photosModel.pickerSelectedText ) {
                    photosModel.pickerTextChange()
                }
                TextEditor(text: $photosModel.editorPhotoText)
                    .lineSpacing(5)
                    .frame(height:50)
                    .padding(.all, 2.0)
                    .border(.black)
                    .onChange(of: photosModel.editorPhotoText) {
                        photosModel.editorTextChange()
                    }
                HStack {
                    Text("Photo Path:")
                    Text(photosModel.currentPhotoPath)
                    Spacer()
                }
                HStack {
                    Button(action: photosModel.selectFolder) {
                        Text("Select Folder")
                    }
                    Button(action: photosModel.saveCurrentText) {
                        Text("Save")
                    }
                    .disabled(!photosModel.photoTextChanged || (photosModel.photoCount == 0))
                    Button(action: photosModel.previousImage) {
                        Image(systemName: "arrowshape.backward.fill")
                    }
                    .disabled(photosModel.prevDisabled)
                    Button(action: photosModel.nextImage) {
                        Image(systemName: "arrowshape.forward.fill")
                    }
                    .disabled(photosModel.nextDisabled)
                    Text("Photo:")
                    //                Text(photosModel.currentIndexString)
                    // The next causes debugger console message: CLIENT ERROR: TUINSRemoteViewController does not
                    // override -viewServiceDidTerminateWithError: and thus cannot react to catastrophic errors beyond
                    // logging them
                    TextField("", value: $photosModel.currentPhotoNumber, format: .number)
                        .disableAutocorrection(true)
                        .frame(width:30)
                        .onSubmit {
                            photosModel.validateIndexEdit()
                        }
                    Text("of")
                    Text(String(photosModel.photoCount))
                    Spacer()
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

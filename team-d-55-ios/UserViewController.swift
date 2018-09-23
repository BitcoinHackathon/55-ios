//
//  UserViewController.swift
//  BitcoinKit-HandsOn
//
//  Created by zizi4n5 on 2018/09/23.
//

import UIKit
import BitcoinKit
import SwiftLocation
import MapKit

class UserViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var joinBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Locator.currentPosition(
            accuracy: .house,
            timeout: Timeout.delayed(60.0),
            onSuccess: { cllocation in
                
                //        let sourceLocation = CLLocationCoordinate2D(latitude:39.173209 , longitude: -94.593933)
                let sourceLocation = cllocation.coordinate
                print("sourceLocation:\(sourceLocation)")
                print("sourceLocationArea:\(sourceLocation.areaString)")

//                let targetAddress = UserDefaults.standard.string(forKey: "targetAddress") ?? "渋谷駅"
                let targetAddress = "渋谷駅"
                Locator.location(
                    fromAddress: targetAddress,
                    onSuccess: { cllocations in
                        
                        //                let destinationLocation = CLLocationCoordinate2D(latitude:38.643172 , longitude: -90.177429)
                        guard let destinationLocation = cllocations.first?.coordinates else {
                            print("targetAddress not found")
                            return
                        }
                        print("destinationLocation:\(destinationLocation)")
                        print("destinationLocationArea:\(destinationLocation.areaString)")

                        //                let sourcePin = CustomPin(pinTitle: "現在地", pinSubTitle: "", location: sourceLocation)
                        //                self.mapView.addAnnotation(sourcePin)
                        let destinationPin = CustomPin(pinTitle: targetAddress, pinSubTitle: "", location: destinationLocation)
                        self.mapView.addAnnotation(destinationPin)
                        
                        let sourcePlaceMark = MKPlacemark(coordinate: sourceLocation)
                        let destinationPlaceMark = MKPlacemark(coordinate: destinationLocation)
                        
                        let directionRequest = MKDirectionsRequest()
                        directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
                        directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
                        directionRequest.transportType = .automobile
                        
                        let directions = MKDirections(request: directionRequest)
                        directions.calculate { (response, error) in
                            guard let directionResonse = response else {
                                if let error = error {
                                    print("we have error getting directions==\(error.localizedDescription)")
                                }
                                return
                            }
                            
                            let route = directionResonse.routes[0]
                            self.mapView.add(route.polyline, level: .aboveRoads)
                            
                            let rect = route.polyline.boundingMapRect
                            self.mapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
                        }
                        
                        //set delegate for mapview
                        self.mapView.delegate = self
                },
                    onFail: { locationError in
                        print("Failed to get location: \(locationError).")
                }
                )
        },
            onFail: { locationError, cllocation in
                print("Failed to get location: \(locationError). Location:\(cllocation.debugDescription)")
        }
        )
    }
    
    //MARK:- MapKit delegates
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 4.0
        return renderer
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

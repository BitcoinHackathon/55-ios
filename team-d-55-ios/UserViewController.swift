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
        
        // MapViewの中心位置を指定.
        mapView.centerCoordinate = CLLocationCoordinate2DMake(35.654168073121134, 139.7014184576829)
        
        // 縮尺を変更.
        // 倍率を指定.
//        let span : MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let span : MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 1)

        // MapViewで指定した中心位置とMKCoordinateSapnで宣言したspanを指定する.
        let region : MKCoordinateRegion = MKCoordinateRegion(center: mapView.centerCoordinate, span: span)
        
        // MapViewのregionプロパティにregionを指定.
        mapView.region = region

        
        //        let sourceLocation = CLLocationCoordinate2D(latitude:39.173209 , longitude: -94.593933)
        let sourceLocation = Locator.currentLocation!.coordinate
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
                    
                    var rect = route.polyline.boundingMapRect
                    let offset = 2000.0
                    rect.origin.x = rect.origin.x - offset / 2.0
                    rect.origin.y = rect.origin.y - offset / 2.0
                    rect.size.width = rect.size.width + offset
                    rect.size.height = rect.size.height + offset
                    self.mapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
                }
                
                //set delegate for mapview
                self.mapView.delegate = self
            },
            onFail: { locationError in
                print("Failed to get location: \(locationError).")
            }
        )
        
        Locator.subscribePosition(
            accuracy: .house,
            onUpdate: { cllocation in
                print("UserView: New location received: \(cllocation)")
                print("UserView: New locationArea:\(cllocation.coordinate.areaString)")
                // TODO 位置情報が変更されたタイミングで、UnLock Scriptを毎回実施する
            },
            onFail: { locationError, last in
                print("UserView: Failed with error: \(locationError)")
            }
        )
    }
    
    
    @IBAction func join(_ sender: Any) {
        
    }
    
    
    
    //MARK:- MapKit delegates
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 4.0
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if (annotation is MKUserLocation) {
            // ユーザの現在地の青丸マークは置き換えない
            return nil
        } else {
            // CustomAnnotationの場合に画像を配置
            let identifier = "Pin"
            var annotationView: MKAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if annotationView == nil {
                annotationView = MKAnnotationView.init(annotation: annotation, reuseIdentifier: identifier)
            }
            annotationView?.image = UIImage.init(named: "bitcoin_cash") // 任意の画像名
            annotationView?.annotation = annotation
            annotationView?.canShowCallout = true  // タップで吹き出しを表示
            return annotationView
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

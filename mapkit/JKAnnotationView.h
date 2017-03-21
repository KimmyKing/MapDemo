//
//  JKAnnotationView.h
//  mapkit
//
//  Created by Cain on 17/3/21.
//  Copyright © 2017年 Goldian. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface JKAnnotationView : MKAnnotationView

+ (JKAnnotationView *)annotationViewWithMapView:(MKMapView *)mapView;

@end

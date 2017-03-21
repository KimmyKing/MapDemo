//
//  JKAnnotationView.m
//  mapkit
//
//  Created by Cain on 17/3/21.
//  Copyright © 2017年 Goldian. All rights reserved.
//

#import "JKAnnotationView.h"

@implementation JKAnnotationView

+ (JKAnnotationView *)annotationViewWithMapView:(MKMapView *)mapView
{
    JKAnnotationView *annView = (JKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"ann"];
    
    if (!annView) {
        annView = [[JKAnnotationView alloc]initWithAnnotation:nil reuseIdentifier:@"ann"];
        annView.canShowCallout = YES;
    }
    
    
    return annView;
}

@end

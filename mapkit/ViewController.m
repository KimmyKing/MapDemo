//
//  ViewController.m
//  mapkit
//
//  Created by Cain on 17/2/22.
//  Copyright © 2017年 Goldian. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>
#import "JKAnnotationView.h"

@interface ViewController ()<MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITextField *keywordTF;

@end

@implementation ViewController

//MARK: -
//MARK: -- 点击按钮
- (IBAction)clickButton:(id)sender {
    
    //添加圆形覆盖物
    [_mapView removeOverlays:_mapView.overlays];
    MKCircle *circle = [MKCircle circleWithCenterCoordinate:_mapView.centerCoordinate radius:500];
    [_mapView addOverlay:circle];
}

//MARK: -
//MARK: -- 点击键盘return键
- (IBAction)DidEndOnExit:(UITextField *)sender {
    
    //再次检索移除之前的覆盖物和标注
    [_mapView removeOverlays:_mapView.overlays];
    [_mapView removeAnnotations:_mapView.annotations];
    
    //检索用户附近范围
    MKLocalSearchRequest *searchRequest = [[MKLocalSearchRequest alloc]init];
    searchRequest.region = MKCoordinateRegionMakeWithDistance(_mapView.userLocation.coordinate, 2000, 2000);
    
    //检索兴趣点关键字
    searchRequest.naturalLanguageQuery = sender.text;
    
    MKLocalSearch *search = [[MKLocalSearch alloc]initWithRequest:searchRequest];
    //开始检索
    __weak typeof(self) weakself = self;
    [search startWithCompletionHandler:^(MKLocalSearchResponse * _Nullable response, NSError * _Nullable error) {
        NSArray *array = response.mapItems;
        for (int i=0; i<array.count; i++) {
            MKMapItem * item=array[i];
            MKPointAnnotation * point = [[MKPointAnnotation alloc]init];
            point.title=item.name;
            //拼接地址
            NSString *address = [NSString stringWithFormat:@"%@%@%@",item.placemark.locality,item.placemark.subLocality,item.placemark.thoroughfare];
            point.subtitle= address;
            point.coordinate=item.placemark.coordinate;
            [weakself.mapView addAnnotation:point];
            
            //设置地图显示范围正好显示所有的标注
            weakself.mapView.region = response.boundingRegion;
        }
    }];
    
}

//MARK: -  MKMapViewDelegate
//MARK: -- 选中大头针,开始导航
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    
    //拦截点击用户位置大头针事件
    if (![view isKindOfClass:[JKAnnotationView class]]) {
        return;
    }
    //移除上次导航的覆盖物
    [mapView removeOverlays:mapView.overlays];
    
    //将选中的大头针作为终点
    CLLocationCoordinate2D selectedCoordinate = view.annotation.coordinate;
    MKPlacemark *destinationPlacemark = [[MKPlacemark alloc]initWithCoordinate:selectedCoordinate];
    MKMapItem *destination = [[MKMapItem alloc]initWithPlacemark:destinationPlacemark];
    
    //起点为用户当前位置
    MKMapItem *source = [MKMapItem mapItemForCurrentLocation];
    
    //创建导航对象
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc]init];
    request.source = source;
    request.destination = destination;
    request.transportType = MKDirectionsTransportTypeAny;
    
    MKDirections *directions = [[MKDirections alloc]initWithRequest:request];
    
    __weak typeof(self) weakself = self;
    //开始导航
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse * _Nullable response, NSError * _Nullable error) {
        //错误处理
        if (error) {
            return;
        }
        
        //取出导航结果中的第一条导航路径
        MKRoute *route = response.routes.firstObject;
        
        //添加起点到起点路口的覆盖物
        CLLocationCoordinate2D start[2];
        start[0] = mapView.userLocation.coordinate;
        start[1] = route.steps.firstObject.polyline.coordinate;
        MKPolyline *startline = [MKPolyline polylineWithCoordinates:start count:2];
        [mapView addOverlay:startline];
        
        //添加终点到终点路段的覆盖物
        CLLocationCoordinate2D end[2];
        end[0] = selectedCoordinate;
        end[1] = route.steps.lastObject.polyline.coordinate;
        MKPolyline *endline = [MKPolyline polylineWithCoordinates:end count:2];
        [mapView addOverlay:endline];
        
        
        for (MKRouteStep *step in route.steps) {
            //添加线路覆盖物
            [weakself.mapView addOverlay:step.polyline];
        }
    }];
    
    //根据起点和终点的经纬度自适应显示地图范围
    MKMapPoint endPoint = MKMapPointForCoordinate(selectedCoordinate);
    MKMapPoint startPoint = MKMapPointForCoordinate(mapView.userLocation.coordinate);
    
    MKMapRect endRect = MKMapRectMake(endPoint.x, endPoint.y, 0, 0);
    MKMapRect startRect = MKMapRectMake(startPoint.x, startPoint.y, 0, 0);
    
    [mapView setVisibleMapRect:MKMapRectUnion(endRect, startRect) animated:YES];
    
    
    
}

//MARK: -  MKMapViewDelegate
//MARK: --自定义大头针样式
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    //如果是用户大头针,拦截
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    JKAnnotationView *anntotationView = [JKAnnotationView annotationViewWithMapView:mapView];
    
    anntotationView.image = [UIImage imageNamed:@"1"];
    anntotationView.canShowCallout = YES;
    
    return anntotationView;
}


//MARK: -  MKMapViewDelegate
//MARK: -- 地图开始获取用户位置时
- (void)mapViewWillStartLocatingUser:(MKMapView *)mapView
{
    //初始化地图的显示范围
    [mapView setRegion:MKCoordinateRegionMakeWithDistance(mapView.centerCoordinate, 4000, 4000) animated:YES];
}

//MARK: -  MKMapViewDelegate
//MARK: -- 设置覆盖物参数
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKCircle class]]) {
        //圆形覆盖物
        MKCircleRenderer *renderer = [[MKCircleRenderer alloc]initWithCircle:overlay];
        renderer.fillColor = [UIColor redColor];
        renderer.strokeColor = [UIColor cyanColor];
        renderer.lineWidth = 2;
        renderer.alpha = 0.3;
        return renderer;
    }else{
        //线形覆盖物
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        renderer.lineWidth = 5;
        renderer.strokeColor = [UIColor orangeColor];
        return renderer;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _mapView.showsUserLocation = YES;
    _mapView.userTrackingMode = MKUserTrackingModeFollow;
    _mapView.delegate = self;
}

@end

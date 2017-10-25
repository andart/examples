//
//  MapMeetingViewController.swift
//  TopSpin
//
//  Created by Andrey Artemenko on 23/08/2017.
//

import UIKit
import MapKit

class MapMeetingViewController: BaseViewController {
    
    fileprivate var frc: NSFetchedResultsController<NSFetchRequestResult>?
    fileprivate let mapView = TSMapView()
    fileprivate let initialLocation = CLLocation(latitude: 55.752017, longitude: 37.617270)
    fileprivate var regionRadius: CLLocationDistance = 20_000
    fileprivate var usualRadius: CLLocationDistance = 2000
    fileprivate let cellHeight: CGFloat = 168
    fileprivate var meetings = [Meeting]()
    fileprivate var isLoading = false
    fileprivate var isNeedUpdate = false
    fileprivate var meeting: Meeting?
    
    lazy var collectionView: MapCollectionView = {
        [unowned self] in
        
        let flow = UICollectionViewFlowLayout()
        flow.minimumLineSpacing = 8
        
        let collectionView = MapCollectionView(frame: self.view.bounds, collectionViewLayout: flow)
        collectionView.backgroundColor = .clear
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset.top = screenSize.height
        collectionView.showsVerticalScrollIndicator = false
        
        collectionView.register(MeetingFeedCollectionViewCell.self)
        
        return collectionView
    }()
    
    class func create(with meeting: Meeting) -> MapMeetingViewController {
        let vc = MapMeetingViewController()
        vc.meeting = meeting
        
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        
        mapView.frame = view.bounds
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        
        view.addSubview(mapView)
        
        initFRC()
        configureAnnotations()
        
        view.addSubview(collectionView)
        
        centerMapOnLocation(initialLocation, radius: regionRadius)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        var radius = regionRadius
        if meeting != nil {
            radius = usualRadius
        } else if let r = Session.shared.meetingFilter.radius?.doubleValue {
            radius = r
        }
        centerMapOnLocation(meeting?.court?.location ?? LocationManager.shared.location ?? initialLocation, radius: radius)
    }
    
    func centerMapOnLocation(_ location: CLLocation, radius: CLLocationDistance) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, radius * 2.0, radius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func loadMeetings(at location: CLLocationCoordinate2D, radius: Float) {
        if isLoading {
            API.shared.cancelRequest(.GET, path: MeetingPaths.mettings.rawValue)
        }
        
        isLoading = true
        let filter = Meeting.Filter(location: location, radius: NSNumber(value: radius * 0.5), gender: Session.shared.meetingFilter.gender, minLevel: Session.shared.meetingFilter.minLevel, maxLevel: Session.shared.meetingFilter.maxLevel)
        Meeting.getMeetings(with: .forgo, filter: filter, fromMap: true) { [weak self] (meetings, error) in
            if let stronSelf = self {
                stronSelf.isLoading = false
            }
        }
    }
    
    func initFRC() {
        let predicate = NSPredicate(format: "%K.%K != %@ AND %K != nil", MeetingRelationships.owner.rawValue, UserAttributes.userId.rawValue, Session.shared.userId ?? 0, MeetingAttributes.meetingId.rawValue)
        frc = Meeting.mr_fetchAllSorted(by: "court.courtId,timeStart", ascending: true, with: predicate, groupBy: "court.courtId", delegate: self)
        do {
            try frc?.performFetch()
        } catch {
            print("")
        }
    }
    
    func configureAnnotations() {
        mapView.removeAnnotations(mapView.annotations)
        
        guard let count = frc?.sections?.count else {
            return
        }
        
        for section in 0..<count {
            let indexPath = IndexPath(item: 0, section: section)
            if let annotation = frc?.object(at: indexPath) as? Meeting, let numberOfPoint = frc?.sections?[section].numberOfObjects {
                annotation.annotationCount = numberOfPoint
                annotation.section = section

                mapView.addAnnotation(annotation)
            }
        }
    }
    
    func showMeetings(at section: Int) {
        guard let numberOfObjects = frc?.sections?[section].numberOfObjects else {
            return
        }
        
        for item in 0..<numberOfObjects {
            if let meeting = frc?.object(at: IndexPath(item: item, section: section)) as? Meeting {
                meetings.append(meeting)
            }
        }
        
        collectionView.performBatchUpdates({ 
            self.collectionView.reloadSections(IndexSet(integer: 0))
        }) { (finish) in
            if finish {
                let y = self.meetings.count > 1 ? self.cellHeight + 68 : self.cellHeight + 48
                self.collectionView.setContentOffset(CGPoint(x: 0, y: -(screenSize.height - y)), animated: true)
            }
        }
    }
    
    func hideMeetings() {
        meetings.removeAll()
        collectionView.reloadSections(IndexSet(integer: 0))
    }
    
}

extension MapMeetingViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        loadMeetings(at: mapView.region.center, radius: Float(mapView.radius))
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKUserLocation.self) {
            var pin = mapView.dequeueReusableAnnotationView(withIdentifier: "myPinView")
            if pin == nil {
                pin = MKAnnotationView(annotation: annotation, reuseIdentifier: "myPinView")
            }
            
            pin?.image = UIImage(named: "ic_pin_my_cort")
            
            return pin
        }
        var pin = mapView.dequeueReusableAnnotationView(withIdentifier: "pinView")
        if pin == nil {
            pin = MeetingAnnotationView(annotation: annotation, reuseIdentifier: "pinView")
        }
        
        pin?.image = (pin?.isSelected)! ? UIImage(named: "ic_pin_cort_active") : UIImage(named: "ic_pin_cort")
        
        return pin
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if view.annotation?.isKind(of: MKUserLocation.self) == true {
            return
        }
        
        view.image = UIImage(named: "ic_pin_cort_active")
        UIView.animate(withDuration: 0.3) {
            view.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }
        
        if let annotation = view.annotation as? Meeting, let section = annotation.section {
            showMeetings(at: section)
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if view.annotation?.isKind(of: MKUserLocation.self) == true {
            return
        }
        
        view.image = UIImage(named: "ic_pin_cort")
        UIView.animate(withDuration: 0.3) {
            view.transform = CGAffineTransform.identity
        }
        
        hideMeetings()
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        guard let meeting = meeting else {
            return
        }
        mapView.selectAnnotation(meeting, animated: true)
    }
    
}

extension MapMeetingViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        isNeedUpdate = false
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if type == .insert || type == .delete {
            isNeedUpdate = true
        }
        
        if type == .update && meetings.count > 0 {
            collectionView.reloadData()
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if isNeedUpdate {
            configureAnnotations()
        }
    }
    
}

extension MapMeetingViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width - 16, height: cellHeight)
    }
    
}

extension MapMeetingViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return meetings.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(MeetingFeedCollectionViewCell.self, forIndexPath: indexPath)
    }
    
}

extension MapMeetingViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? MeetingFeedCollectionViewCell, meetings.count > indexPath.item {
            cell.meeting = meetings[indexPath.item]
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if meetings.count > indexPath.item {
            let meeting = meetings[indexPath.item]
            navigationController?.pushViewController(MeetingViewController.create(with: meeting), animated: true)
        }
    }
}

extension MapMeetingViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < -(screenSize.height - 60), let annotation = mapView.selectedAnnotations.first as? Meeting {
             mapView.deselectAnnotation(annotation, animated: true)
        }
    }
}

class MeetingAnnotationView: MKAnnotationView {
    
    let label = UILabel()
    
    override var annotation: MKAnnotation? {
        didSet {
            if let an = annotation as? Meeting, let count = an.annotationCount {
                label.text = count > 1  ? "\(count)" : ""
            } else {
                label.text = ""
            }
        }
    }
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        label.frame = frame
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 20, weight: UIFontWeightMedium)
        label.textAlignment = .center
        
        addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                label.frame.origin.y -= 4
            } else {
                label.frame.origin.y = 0
            }
        }
    }
    
}

class MapCollectionView: UICollectionView {
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if point.y < 0 {
            return nil
        }
        
        return hitView
    }
}

//
//  EventViewController.swift
//  FinalProject
//
//  Created by Daniela Velasquez on 3/8/16.
//  Copyright © 2016 Mahisoft. All rights reserved.
//

import UIKit
import EventKit

class EventViewController: UIViewController {
    
    @IBOutlet weak var eventName: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var startDate: NSDate = NSDate()
    var eventId: String = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if eventId != ""{
            loadEvent()
        }
        
        datePicker.setDate(startDate, animated: true)
        
        //Add gesture from hide keyboard when the user touch the screen
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(EventViewController.hideKeyboard)))
        
    }
    
    
    // MARK: - Keyboard management Methods
    /*
     * @author: Daniela Velasquez
     * Hide the keyboard
     */
    func hideKeyboard(){
        view.endEditing(true)
    }
    
    //MARK: Other Methods
    func loadEvent(){
        
        let store = EKEventStore()
        
        store.requestAccessToEntityType(.Event) {(granted, error) in
            
            if let event = store.eventWithIdentifier(self.eventId){
                self.eventName.text = event.title
                self.startDate = event.startDate
                self.datePicker.setDate(self.startDate, animated: true)
            }else{
                
                Support.showGeneralAlert("", message:Messages.mEventDeleted, currentVC: self)
                
                PersistenceManager.instance.deleteEvent(self.eventId)
            }
            
            
        }
        
    }
    //MARK: IBActions
    @IBAction func birthdayChange(sender: UIDatePicker) {
        startDate =  sender.date
    }
    
    @IBAction func goBack(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func addEvent(sender: AnyObject) {
        
        let store = EKEventStore()
        
        dispatch_async(dispatch_get_main_queue()) {
            
            if let event = store.eventWithIdentifier(self.eventId){
                
                store.requestAccessToEntityType(.Event) {(granted, error) in
                    
                    guard granted else { return }
                    
                    event.title = self.eventName.text!
                    event.startDate = self.startDate
                    
                    //1 hour long meeting
                    event.endDate = event.startDate.dateByAddingTimeInterval(60*60)
                    
                    event.calendar = store.defaultCalendarForNewEvents
                    
                    do {
                        try store.saveEvent(event, span: .ThisEvent, commit: true)
                        
                        PersistenceManager.instance.updateEvent(event.startDate, name: event.title, identifier: event.eventIdentifier)
                        
                        Support.showGeneralAlert("", message: Messages.mEventUpdateSuccess, currentVC: self, handlerSuccess:  { (action) in
                            self.goBack(sender)
                        })
                        
                    } catch {
                        Support.showGeneralAlert("", message:Messages.mEventUpdateFail, currentVC: self)
                    }
                }
            }else{
                
                store.requestAccessToEntityType(.Event) {(granted, error) in
                    
                    guard granted else { return }
                    
                    let event = EKEvent(eventStore: store)
                    
                    event.title = self.eventName.text!
                    event.startDate = self.startDate
                    
                    //1 hour long meeting
                    event.endDate = event.startDate.dateByAddingTimeInterval(60*60)
                    
                    event.calendar = store.defaultCalendarForNewEvents
                    
                    do {
                        try store.saveEvent(event, span: .ThisEvent, commit: true)
                        self.eventId = event.eventIdentifier
                        
                        PersistenceManager.instance.saveEvent(event.startDate, name: event.title, identifier: event.eventIdentifier)
                        
                        Support.showGeneralAlert("", message: Messages.mEventAddSuccess, currentVC: self, handlerSuccess:  { (action) in
                            //Go to back
                            self.goBack(sender)
                        })
                        
                    } catch {
                        Support.showGeneralAlert("", message:Messages.mEventAddFail, currentVC: self)
                    }
                }
            }
            
        }
        
    }
    
    @IBAction func deleteEvent(sender: AnyObject) {
        
        PersistenceManager.instance.deleteEvent(self.eventId)
        deleteEvent()
        
    }
    
    func deleteEvent(){
        
        let store = EKEventStore()
        
        store.requestAccessToEntityType(.Event) {(granted, error) in
            if !granted { return }
            let eventToRemove = store.eventWithIdentifier(self.eventId)
            if eventToRemove != nil {
                do {
                    try store.removeEvent(eventToRemove!, span: .ThisEvent, commit: true)
                    
                    Support.showGeneralAlert("", message: Messages.mEventDeleteSuccess, currentVC: self, handlerSuccess:  { (action) in
                        self.goBack(self)
                    })
                    
                } catch {
                    Support.showGeneralAlert("", message:Messages.mEventDeleteFail, currentVC: self)
                }
            }
        }
    }
}

extension EventViewController: UITextFieldDelegate{
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

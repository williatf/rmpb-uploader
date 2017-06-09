//
//  DraggableItem.swift
//  RMPBUploader
//
//  Created by Todd Williams on 9/2/15.
//  Copyright (c) 2015 Todd Williams. All rights reserved.
//

import Cocoa

// A Class for the cropr view draggable part
class DraggableItem: NSView {

    // set the blacked out color
    let itemColor = NSColor.black
    
    // create the left and right points
    var leftControlLocation = NSPoint()
    var rightControlLocation = NSPoint()
    
    // keep track of which side is being dragged, the last dragged location and whether or not it's currently being dragged
    var activeControl = String()
    var lastDragLocation = NSPoint()
    var dragging = false
    
    // The paths for the left and right control bars
    var leftControl = NSBezierPath()
    var rightControl = NSBezierPath()
    
    // Creates the default box on initialization
    override init(frame: NSRect) {
        super.init(frame: frame)
        self.setItemPropertiesToDefault()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // -----------------------------------
    // Draw the crop bars
    // -----------------------------------
    
    override func draw(_ rect:NSRect) {
        
        // clear the old controls
        leftControl.removeAllPoints()
        rightControl.removeAllPoints()
        
        // set the color of the draggable item
        self.itemColor.set()
        
        leftControl.move(to: NSMakePoint(leftControlLocation.x, 0))
        leftControl.line(to: NSMakePoint(leftControlLocation.x,922))
        leftControl.appendRect(
            NSMakeRect(leftControlLocation.x, 0, 10, 10)
        )
        
        rightControl.move(to: NSMakePoint(rightControlLocation.x, 0))
        rightControl.line(to: NSMakePoint(rightControlLocation.x,922))
        rightControl.appendRect(
            NSMakeRect(rightControlLocation.x-10, 0, 10, 10)
        )
        
        leftControl.stroke()
        rightControl.stroke()
        
        // draw masking rectangles
        NSColor.blue.withAlphaComponent(0.25).set()
        NSBezierPath.fill(NSMakeRect(0, 0, leftControlLocation.x, 922))
        NSBezierPath.fill(NSMakeRect(rightControlLocation.x, 0, 620, 922))
        
        crop.left = Int(leftControlLocation.x)
        crop.right = Int(rightControlLocation.x)
    }
    
    // -----------------------------------
    // Modify the item location
    // -----------------------------------
    
    func offsetLocation(_ x:CGFloat,y:CGFloat){
        
        switch activeControl {
            case "left":
                leftControlLocation.x += x
                if leftControlLocation.x < 0 {
                    leftControlLocation.x = 0
                } else if leftControlLocation.x > rightControlLocation.x { leftControlLocation.x = rightControlLocation.x
                }
            case "right":
                rightControlLocation.x += x
                if rightControlLocation.x < leftControlLocation.x {
                    rightControlLocation.x = leftControlLocation.x
                } else if rightControlLocation.x > 620 {
                    rightControlLocation.x = 620
                }
            default:
                self.print("no active control")
        }

        // tell the display to redraw
        self.needsDisplay = true
        
    }
    
    
    // -----------------------------------
    // Hit test the item
    // -----------------------------------
    
    func isPointInItem(_ testPoint:NSPoint) -> Bool {

        if leftControl.contains(testPoint) {
            activeControl = "left"
            return true
        }
        
        if rightControl.contains(testPoint) {
            activeControl = "right"
            return true
        }
        
        return false
    }
    
    // -----------------------------------
    // Handle Mouse Events
    // -----------------------------------
    
    override func mouseDown(with theEvent: NSEvent) {
        
        var clickLocation = NSPoint()
        var itemHit = false
        
        // convert the click location into the view coords
        clickLocation = self.convert(theEvent.locationInWindow, from: nil)
        
        // did the click occur in the item?
        itemHit = self.isPointInItem(clickLocation)
        
        // Yes it did, note that we're starting to drag
        if itemHit {
            // flag the dragging instance variable
            dragging = true

            // store the starting click location
            lastDragLocation = clickLocation
            
            // set the cursor
            NSCursor.closedHand().push()
        }
    }
    
    override func mouseDragged(with theEvent: NSEvent) {
    
        if dragging {
            let newDragLocation = self.convert(theEvent.locationInWindow, from: nil)
            
            // offset by the change in mouse movement
            self.offsetLocation(newDragLocation.x - lastDragLocation.x, y: newDragLocation.y - lastDragLocation.y)
            
            // save the new drag location for the next time
            lastDragLocation = newDragLocation
            
        }
    }
    
    override func mouseUp(with theEvent: NSEvent) {
        
        dragging = false
        
        // finished dragging, restore the cursor
        NSCursor.pop()
        
        
    }
    
    
    func setItemPropertiesToDefault(){
        leftControlLocation = NSMakePoint(CGFloat(crop.left), 0)
        rightControlLocation = NSMakePoint(CGFloat(crop.right), 0)
    }
    
}

//
//  DrawView.swift
//  TouchTracker
//
//  Created by Shehab Saqib on 04/06/2016.
//  Copyright © 2016 Shehab Saqib. All rights reserved.
//

import UIKit

class DrawView: UIView, UIGestureRecognizerDelegate {
    
    //var currentLine: Line?
    var currentLines = [NSValue:Line]()
    var finishedLines = [Line]()
    var selectedLineIndex: Int? {
        didSet {
            if selectedLineIndex == nil {
                let menu = UIMenuController.sharedMenuController()
                menu.setMenuVisible(false, animated: true)
            }
        }
    }
    var moveRecogniser: UIPanGestureRecognizer!
    
    @IBInspectable var finishedLineColor: UIColor = UIColor.blackColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var currentLineColor: UIColor = UIColor.redColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var lineThickness: CGFloat = 10 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    func strokeLine(line: Line) {
        let path = UIBezierPath()
        path.lineWidth = lineThickness
        path.lineCapStyle = CGLineCap.Round
        
        path.moveToPoint(line.begin)
        path.addLineToPoint(line.end)
        path.stroke()
    }
    
    override func drawRect(rect: CGRect) {
        
        finishedLineColor.setStroke()
        
        for line in finishedLines {
            strokeLine(line)
        }
        
        currentLineColor.setStroke()
        for (_, line) in currentLines {
            strokeLine(line)
        }
        
        if let index = selectedLineIndex {
            UIColor.greenColor().setStroke()
            let selectedLine = finishedLines[index]
            strokeLine(selectedLine)
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        //let touch = touches.first!
        
        //let location = touch.locationInView(self)
        
        //currentLine = Line(begin: location, end: location)
        
        print(__FUNCTION__)
        
        for touch in touches {
            let location = touch.locationInView(self)
            let newLine = Line(begin: location, end: location)
            
            let key = NSValue(nonretainedObject: touch)
            currentLines[key] = newLine
        }
        
        setNeedsDisplay()
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        //let touch = touches.first!
        //let location = touch.locationInView(self)
        //currentLine?.end = location
        
        print(__FUNCTION__)
        
        for touch in touches {
            let key = NSValue(nonretainedObject: touch)
            currentLines[key]?.end = touch.locationInView(self)
        }
        
        setNeedsDisplay()
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
       /* if var line = currentLine {
            let touch = touches.first!
            let location = touch.locationInView(self)
            line.end = location
            
            finishedLines.append(line)
        }
        currentLine = nil */
        
        print(__FUNCTION__)
        
        for touch in touches {
            let key = NSValue(nonretainedObject: touch)
            if var line = currentLines[key] {
                line.end = touch.locationInView(self)
                
                finishedLines.append(line)
                currentLines.removeValueForKey(key)
            }
        }
        
        setNeedsDisplay()
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        
        print(__FUNCTION__)
        
        currentLines.removeAll()
        setNeedsDisplay()
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        let doubleTapRecogniser = UITapGestureRecognizer(target: self, action: "doubleTap:")
        doubleTapRecogniser.numberOfTapsRequired = 2
        doubleTapRecogniser.delaysTouchesBegan = true
        addGestureRecognizer(doubleTapRecogniser)
        
        let tapRecogniser = UITapGestureRecognizer(target: self, action: "tap:")
        tapRecogniser.delaysTouchesBegan = true
        tapRecogniser.requireGestureRecognizerToFail(doubleTapRecogniser)
        addGestureRecognizer(tapRecogniser)
        
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: "longPress:")
        addGestureRecognizer(longPressRecogniser)
        
        moveRecogniser = UIPanGestureRecognizer(target: self, action: "moveLine:")
        moveRecogniser.delegate = self
        moveRecogniser.cancelsTouchesInView = false
        addGestureRecognizer(moveRecogniser)
        
    }
    
    func tap(gestureRecogniser: UIGestureRecognizer) {
        print("Recognised a tap")
        
        let point = gestureRecogniser.locationInView(self)
        selectedLineIndex = indexOfLineAtPoint(point)
        
        let menu = UIMenuController.sharedMenuController()
        
        if selectedLineIndex != nil {
            //Make drawview the target of menu item action messages
            becomeFirstResponder()
            
            let deleteItem = UIMenuItem(title: "Delete", action: "deleteLine:")
            menu.menuItems = [deleteItem]
            
            menu.setTargetRect(CGRect(x: point.x, y: point.y, width: 2, height: 2), inView: self)
            menu.setMenuVisible(true, animated: true)
        } else {
            menu.setMenuVisible(false, animated: true)
        }
        
        setNeedsDisplay()
    }
    
    func doubleTap(gestureRecogniser: UIGestureRecognizer) {
        print("Recognised a double tap")
        
        selectedLineIndex = nil
        currentLines.removeAll(keepCapacity: false)
        finishedLines.removeAll(keepCapacity: false)
        setNeedsDisplay()
    }
    
    func indexOfLineAtPoint(point: CGPoint) -> Int? {
        
        //Find a line close to point
        for (index, line) in finishedLines.enumerate() {
            let begin = line.begin
            let end = line.end
            
            //Check a few points on the line
            for t in CGFloat(0).stride(to: 1.0, by: 0.05) {
                let x = begin.x + ((end.x - begin.x) * t)
                let y = begin.y + ((end.y - begin.y) * t)
                
                //if the tapped point is within 20 points, let's return this line
                if hypot(x - point.x, y - point.y) < 20.0 {
                    return index
                }
            }
        }
        
        //If nothing is close enough to the tapped point, then we did not select a line
        return nil
    }
    
    func deleteLine(sender: AnyObject) {
        //remove the selected line from the list of finishedLine
        if let index = selectedLineIndex {
            finishedLines.removeAtIndex(index)
            selectedLineIndex = nil
            
            setNeedsDisplay()
        }
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    func longPress(gestureRecogniser: UIGestureRecognizer) {
        print("Recognised a long press")
        
        if gestureRecogniser.state == .Began {
            let point = gestureRecogniser.locationInView(self)
            selectedLineIndex = indexOfLineAtPoint(point)
            
            if selectedLineIndex != nil {
                currentLines.removeAll(keepCapacity: false)
            }
        }
        else if gestureRecogniser.state == .Ended {
            selectedLineIndex = nil
        }
        setNeedsDisplay()
    }
    
    func moveLine(gestureRecogniser: UIPanGestureRecognizer) {
        print("Recognised a pan")
        
        //If a line is selected...
        if let index = selectedLineIndex {
            if gestureRecogniser.state == .Changed {
                let translation = gestureRecogniser.translationInView(self)
                
                finishedLines[index].begin.x += translation.x
                finishedLines[index].begin.y += translation.y
                finishedLines[index].end.x += translation.x
                finishedLines[index].end.y += translation.y
                
                gestureRecogniser.setTranslation(CGPoint.zero, inView: self)
                
                setNeedsDisplay()
            }
        }
        else {
            return
        }
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

//
//  ViewController.swift
//  OpenMultitouchDemo
//
//  Created by Takuto Nakamura on 2019/09/12.
//  Copyright © 2019 Takuto Nakamura. All rights reserved.
//

import Cocoa
import OpenMultitouchSupport

class ViewController: NSViewController {
    @IBOutlet var textView: NSTextView!

    let manager = OpenMTManager.shared()
    var listener: OpenMTListener! = nil
    let fmt = DateFormatter()
    var data = [TouchData]()
    var texts = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        fmt.dateFormat = "HH:mm:ss.SSSS"
        textView.font = NSFont(name: "menlo", size: 13)
//        listener = manager?.addListener(withTarget: self, selector: #selector(process))
        listener = manager?.addListener(callback: { event in
            guard let event = event else { return }
            self.process(event)
        })
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    override func viewWillDisappear() {
        manager?.remove(listener)
    }

    @objc func process(_ event: OpenMTEvent) {
        guard let touches = event.touches as NSArray as? [OpenMTTouch] else { return }
        if touches.count > 0 {
            touches.forEach { touch in
                let state: String
                switch touch.state {
                case .notTouching: state = "not-touch"
                case .starting: state = "start"
                case .hovering: state = "hover"
                case .making: state = "make"
                case .touching: state = "touch"
                case .breaking: state = "break"
                case .lingering: state = "linger"
                case .leaving: state = "leave"
                @unknown default: return
                }
                data.append(TouchData(id: touch.identifier,
                                      pos: FloatPair(x: touch.posX, y: touch.posY),
                                      total: touch.total,
                                      pressure: touch.pressure,
                                      axis: FloatPair(x: touch.majorAxis, y: touch.minorAxis),
                                      angle: touch.angle,
                                      density: touch.density,
                                      state: state,
                                      timestamp: fmt.string(from: Date()),
                                      deviceType: event.device?.familyID))
                updateTextView(data.last!.explanation)
            }
        } else {
            data.removeAll()
        }
    }

    func updateTextView(_ text: String) {
        DispatchQueue.main.async {
            self.texts.append(text)
            if self.texts.count > 50 {
                self.texts.removeFirst()
            }
            self.textView.string = self.texts.joined(separator: "\n")
            self.textView.scrollToEndOfDocument(nil)
        }
    }
}

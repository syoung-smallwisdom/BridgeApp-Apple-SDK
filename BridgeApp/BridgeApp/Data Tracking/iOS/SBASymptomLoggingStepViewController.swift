//
//  SBASymptomLoggingStepViewController.swift
//  BridgeApp (iOS)
//
//  Copyright © 2018 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import UIKit

open class SBASymptomLoggingStepViewController: RSDTableStepViewController {
    
    override open func registerReuseIdentifierIfNeeded(_ reuseIdentifier: String) {
        guard !_registeredIdentifiers.contains(reuseIdentifier) else { return }
        _registeredIdentifiers.insert(reuseIdentifier)
        
        let reuseId = RSDFormUIHint(rawValue: reuseIdentifier)
        switch reuseId {
        case .logging:
            tableView.register(SBASymptomLoggingCell.nib, forCellReuseIdentifier: reuseIdentifier)
        default:
            super.registerReuseIdentifierIfNeeded(reuseIdentifier)
        }
    }
    private var _registeredIdentifiers = Set<String>()

}

public protocol SBASymptomLoggingCellDelegate : class, NSObjectProtocol {
    
    func didChangeSeverity(for cell: SBASymptomLoggingCell, selected: Int)
    
    func didTapTime(for cell: SBASymptomLoggingCell)
    
    func didTapAddDuration(for cell: SBASymptomLoggingCell)

    
}

/// Table view cell for logging symptoms.
open class SBASymptomLoggingCell: RSDTableViewCell {
    
    public weak var delegate: SBASymptomLoggingCellDelegate?
    
    /// The nib to use with this cell. Default will instantiate a `SBASymptomLoggingCell`.
    open class var nib: UINib {
        let bundle = Bundle(for: SBASymptomLoggingCell.self)
        let nibName = String(describing: SBASymptomLoggingCell.self)
        return UINib(nibName: nibName, bundle: bundle)
    }
    
    @IBOutlet open var titleLabel: UILabel!
    @IBOutlet open var subtitleLabel: UILabel!
    @IBOutlet open var severityButtons: [SBASeverityButton]!
    @IBOutlet open var separatorLines: [UIView]!
    @IBOutlet open var labels: [UILabel]!
    @IBOutlet open var timeButton: RSDUnderlinedButton?
    @IBOutlet open var durationButton: RSDUnderlinedButton?
    @IBOutlet open var detailDisclosureButton: UIButton?
    @IBOutlet open var medicationTimingButtons: [UIButton]?
    @IBOutlet open var notesTextView: UITextView?
    
    /// Override to set the content view background color to the color of the table background.
    override open var tableBackgroundColor: UIColor! {
        didSet {
            self.contentView.backgroundColor = tableBackgroundColor
        }
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        self.titleLabel.textColor = UIColor.rsd_headerTitleLabel
        self.subtitleLabel.textColor = UIColor.rsd_headerDetailLabel
        for label in self.labels {
            label.textColor = UIColor.rsd_headerTitleLabel
        }
        for line in self.separatorLines {
            line.backgroundColor = UIColor.rsd_cellSeparatorLine
        }
    }
    
    override open var tableItem: RSDTableItem! {
        didSet {
            guard let loggingItem = tableItem as? SBASymptomTableItem
                else {
                    return
            }
            titleLabel.text = loggingItem.loggedResult.text
            subtitleLabel.text = loggingItem.loggedResult.detail
            let severity = loggingItem.severity?.rawValue ?? -1
            for button in self.severityButtons {
                button.isSelected = (severity == button.tag)
            }
            timeButton?.setTitle(DateFormatter.localizedString(from: loggingItem.time, dateStyle: .none, timeStyle: .short), for: .normal)
            let durationTitle = loggingItem.duration ?? Localization.localizedString("ADD_DURATION_BUTTON")
            durationButton?.setTitle(durationTitle, for: .normal)
            notesTextView?.text = loggingItem.notes
        }
    }
    
    @IBAction func severityTapped(_ sender: SBASeverityButton) {
        if sender.isSelected {
            sender.isSelected = false
            self.delegate?.didChangeSeverity(for: self, selected: -1)
        }
        else {
            for button in self.severityButtons {
                button.isSelected = (sender.tag == button.tag)
            }
            self.delegate?.didChangeSeverity(for: self, selected: sender.tag)
        }
    }
    
    @IBAction func timeTapped(_ sender: Any) {
        self.delegate?.didTapTime(for: self)
    }
    
    @IBAction func addDurationTapped(_ sender: Any) {
        self.delegate?.didTapAddDuration(for: self)
    }
}

@IBDesignable
open class SBASeverityButton : UIButton {
    
    override open var tag: Int {
        didSet {
            _updateBackgroundColor()
        }
    }
    
    override open var isSelected: Bool {
        didSet {
            _updateBackgroundColor()
        }
    }
    
    private func _updateBackgroundColor() {
        setTitleColor(UIColor.rsd_headerDetailLabel, for: .normal)
        setTitleColor(UIColor.rsd_headerTitleLabel, for: .selected)
        self.backgroundColor = _fillColor()
        self.layer.borderColor = _strokeColor().cgColor
    }
    
    private func _fillColor() -> UIColor {
        guard self.tag < UIColor.sba_severityFill.count, isSelected
            else {
                return UIColor.white
        }
        return UIColor.sba_severityFill[self.tag]
    }
    
    private func _strokeColor() -> UIColor {
        guard self.tag < UIColor.sba_severityStroke.count, isSelected
            else {
                return UIColor.rsd_cellSeparatorLine
        }
        return UIColor.sba_severityStroke[self.tag]
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 3.0
        layer.borderWidth = 1.0
        _updateBackgroundColor()
    }
}

/// A simple button that draws a open/closed chevron that can be used to indicate whether or not
/// the details are expanded.
@IBDesignable
public final class RSDDetailsChevronButton : UIButton {
    
    public override var isSelected: Bool {
        didSet {
            chevron.setOpen(isSelected, animated: false)
        }
    }
    private var _animating: Bool = false
    
    /// Set selected with animation
    public func setSelected(_ isSelected: Bool, animated: Bool) {
        chevron.setOpen(isSelected, animated: animated)
        self.isSelected = isSelected
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private var chevron: ChevronFlipView!
    
    private func commonInit() {
        let bounds = CGRect(x: 0, y: 0, width: 20, height: 12)
        chevron = ChevronFlipView(frame: bounds)
        self.addSubview(chevron)
        chevron.rsd_alignToSuperview([.bottom, .trailing], padding: 2)
        chevron.rsd_makeWidth(.equal, bounds.width)
        chevron.rsd_makeHeight(.equal, bounds.height)
    }
}

@IBDesignable
fileprivate class ChevronFlipView : UIView {
    
    var viewDown: ChevronView!
    var viewUp: ChevronView!
    
    public private(set) var isOpen: Bool = false
    
    public func setOpen(_ isOpen: Bool, animated: Bool) {
        guard isOpen != self.isOpen else { return }
        self.isOpen = isOpen
        if isOpen {
            flipOpen(animated: animated)
        } else {
            flipClosed(animated: animated)
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        viewDown = ChevronView(frame: self.bounds, isFlipped: false)
        self.addSubview(viewDown)
        viewDown.rsd_alignAllToSuperview(padding: 0)
        
        viewUp = ChevronView(frame: self.bounds, isFlipped: true)
        self.addSubview(viewDown)
        viewDown.rsd_alignAllToSuperview(padding: 0)
        viewUp.isHidden = true
    }
    
    private func flipClosed(animated: Bool) {
        guard animated else {
            viewUp.isHidden = true
            viewDown.isHidden = false
            return
        }
        
        let transitionOptions: UIViewAnimationOptions = [.transitionFlipFromBottom, .showHideTransitionViews]
        
        UIView.transition(with: viewUp, duration: 1.0, options: transitionOptions, animations: {
            self.viewUp.isHidden = false
        })
        
        UIView.transition(with: viewDown, duration: 1.0, options: transitionOptions, animations: {
            self.viewDown.isHidden = true
        })
    }
    
    private func flipOpen(animated: Bool) {
        guard animated else {
            viewUp.isHidden = false
            viewDown.isHidden = true
            return
        }
        
        let transitionOptions: UIViewAnimationOptions = [.transitionFlipFromTop, .showHideTransitionViews]
        
        UIView.transition(with: viewUp, duration: 1.0, options: transitionOptions, animations: {
            self.viewUp.isHidden = true
        })
        
        UIView.transition(with: viewDown, duration: 1.0, options: transitionOptions, animations: {
            self.viewDown.isHidden = false
        })
    }
}

@IBDesignable
fileprivate class ChevronView : UIView {

    public private(set) var isFlipped: Bool = false
    
    private func currentTransform() -> CATransform3D {
        return isFlipped ? CATransform3DMakeScale(-1, 1, 1) : CATransform3DIdentity
    }
    
    fileprivate var _shapeLayer: CAShapeLayer!
    fileprivate var _rectSize: CGSize!
    
    public init(frame: CGRect, isFlipped: Bool) {
        super.init(frame: frame)
        self.isFlipped = isFlipped
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    fileprivate func commonInit() {
        _rectSize = self.bounds.size
        updateShapeLayer()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        let rectSize = self.bounds.size
        if rectSize != _rectSize {
            _rectSize = rectSize
            updateShapeLayer()
        }
        _shapeLayer.frame = self.layer.bounds
    }
    
    override public func tintColorDidChange() {
        super.tintColorDidChange()
        _shapeLayer.strokeColor = self.tintColor.cgColor
    }
    
    private func updateShapeLayer() {
        
        self.layer.removeAllAnimations()
        _shapeLayer?.removeFromSuperlayer()
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: _rectSize.width / 2, y: _rectSize.height))
        path.addLine(to: CGPoint(x: _rectSize.width, y: 0))
        path.lineCapStyle = .round
        path.lineJoinStyle = .miter
        path.lineWidth = 2
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.lineWidth = path.lineWidth
        shapeLayer.lineCap = kCALineCapRound
        shapeLayer.lineJoin = kCALineJoinMiter
        shapeLayer.frame = self.layer.bounds
        shapeLayer.strokeColor = self.tintColor.cgColor
        shapeLayer.backgroundColor = UIColor.clear.cgColor
        shapeLayer.fillColor = nil
        shapeLayer.strokeEnd = 1
        shapeLayer.transform = currentTransform()
        self.layer.addSublayer(shapeLayer)
        _shapeLayer = shapeLayer
    }
}

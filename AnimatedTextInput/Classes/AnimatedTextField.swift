import UIKit

final internal class AnimatedTextField: UITextField {

    enum TextFieldType {
        case text
        case password
        case numeric
        case selection
    }

    fileprivate let defaultPadding: CGFloat = -16
    fileprivate let clearButtonPadding: CGFloat = -8

    var rightViewPadding: CGFloat
    weak var textInputDelegate: TextInputDelegate?

    var textAttributes: [String: Any]?

    fileprivate var disclosureButtonAction: ((Void) -> Void)?

    override init(frame: CGRect) {
        self.rightViewPadding = defaultPadding

        super.init(frame: frame)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        self.rightViewPadding = defaultPadding

        super.init(coder: aDecoder)

        setup()
    }

    fileprivate func setup() {
        delegate = self
        addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    @discardableResult override func becomeFirstResponder() -> Bool {
        if let alignment = (textAttributes?[NSParagraphStyleAttributeName] as? NSMutableParagraphStyle)?.alignment {
            textAlignment = alignment
        }
        return super.becomeFirstResponder()
    }

    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        return super.rightViewRect(forBounds: bounds).offsetBy(dx: rightViewPadding, dy: 0)
    }

    override func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        return super.clearButtonRect(forBounds: bounds).offsetBy(dx: clearButtonPadding, dy: 0)
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        var width = bounds.width
        if clearButtonMode == .always || clearButtonMode == .unlessEditing {
            width = bounds.width - clearButtonRect(forBounds: bounds).width * 2
        }
        return CGRect(x: bounds.origin.x, y: bounds.origin.y, width: width, height: bounds.height)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        var width = bounds.width
        if clearButtonMode != .never {
            width = bounds.width - clearButtonRect(forBounds: bounds).width * 2
        } else if let _ = rightView {
            width = bounds.width - rightViewRect(forBounds: bounds).width * 2
        }
        return CGRect(x: bounds.origin.x, y: bounds.origin.y, width: width, height: bounds.height)
    }

    func add(disclosureButton button: UIButton, action: @escaping ((Void) -> Void)) {
        let selector = #selector(disclosureButtonPressed)
        if disclosureButtonAction != nil, let previousButton = rightView as? UIButton {
            previousButton.removeTarget(self, action: selector, for: .touchUpInside)
        }
        disclosureButtonAction = action
        button.addTarget(self, action: selector, for: .touchUpInside)
        rightView = button
    }

    @objc fileprivate func disclosureButtonPressed() {
        disclosureButtonAction?()
    }

    @objc fileprivate func textFieldDidChange() {
        if let text = text {
            attributedText = NSAttributedString(string: text, attributes: textAttributes)
        }
        textInputDelegate?.textInputDidChange(textInput: self)
    }
}

extension AnimatedTextField: TextInput {

    func changeReturnKeyType(with newReturnKeyType: UIReturnKeyType) {
        returnKeyType = newReturnKeyType
    }

    func currentPosition(from: UITextPosition, offset: Int) -> UITextPosition? {
        return position(from: from, offset: offset)
    }
    
    func changeClearButtonMode(with newClearButtonMode: UITextFieldViewMode) {
        clearButtonMode = newClearButtonMode
    }

    var currentText: String? {
        get { return text }
        set { self.text = newValue }
    }

    var currentSelectedTextRange: UITextRange? {
        get { return self.selectedTextRange }
        set { self.selectedTextRange = newValue }
    }

    open var currentBeginningOfDocument: UITextPosition? {
        get { return self.beginningOfDocument }
    }
}

extension AnimatedTextField: TextInputError {

    func configureErrorState(with message: String?) {
        placeholder = message
    }

    func removeErrorHintMessage() {
        placeholder = nil
    }
}

extension AnimatedTextField: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        textInputDelegate?.textInputDidBeginEditing(textInput: self)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textInputDelegate?.textInputDidEndEditing(textInput: self)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return textInputDelegate?.textInput(textInput: self, shouldChangeCharactersInRange: range, replacementString: string) ?? true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return textInputDelegate?.textInputShouldBeginEditing(textInput: self) ?? true
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return textInputDelegate?.textInputShouldEndEditing(textInput: self) ?? true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textInputDelegate?.textInputShouldReturn(textInput: self) ?? true
    }
}

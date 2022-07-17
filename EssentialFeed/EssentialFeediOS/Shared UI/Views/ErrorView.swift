//  Copyright © 2021 Andreas Link. All rights reserved.

import UIKit

public final class ErrorView: UIButton {
    var onHide: (() -> Void)?

    public var message: String? {
        get { isVisible ? title(for: .normal) : nil }
        set { newValue == nil ? hideMessage() : show(message: newValue) }
    }

    private var isVisible: Bool {
        return alpha > 0
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        commonInit()
    }

    private func commonInit() {
        backgroundColor = .errorBackgroundColor
        
        setupLabel()
        hideMessage()
        addTarget(self, action: #selector(hideMessageAnimated), for: .touchUpInside)
    }

    private func setupLabel() {
        titleLabel?.textColor = .white
        titleLabel?.textAlignment = .center
        titleLabel?.numberOfLines = 0
        titleLabel?.font = .preferredFont(forTextStyle: .body)
        titleLabel?.adjustsFontForContentSizeCategory = true
    }

    func show(message: String?) {
        setTitle(message, for: .normal)
        contentEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 8)

        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
        }
    }

    @objc
    private func hideMessageAnimated() {
        UIView.animate(
            withDuration: 0.25,
            animations: { self.alpha = 0 },
            completion: { completed in
                if completed { self.hideMessage() }
            }
        )
    }

    private func hideMessage() {
        alpha = 0
        contentEdgeInsets = .init(top: -10.5, left: 8, bottom: -10.5, right: 8)
        setTitle(nil, for: .normal)
        onHide?()
    }
}

private extension UIColor {
    static var errorBackgroundColor: UIColor {
        return UIColor(red: 0.99951404330000004, green: 0.41759261489999999, blue: 0.4154433012, alpha: 1)
    }
}

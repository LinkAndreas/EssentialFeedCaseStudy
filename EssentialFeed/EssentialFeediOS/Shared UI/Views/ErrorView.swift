//  Copyright © 2021 Andreas Link. All rights reserved.

import UIKit

public final class ErrorView: UIView {
    private (set) public lazy var button: UIButton = {
        let button = UIButton()
        button.titleLabel?.textColor = .white
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.addTarget(self, action: #selector(handleButtonAction), for: .touchUpInside)
        return button
    }()

    public var message: String? {
        get { return isVisible ? button.title(for: .normal) : nil }
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
        
        setupButton()
        hideMessage()
    }

    private func setupButton() {
        addSubview(button)

        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: 8),
            button.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: 8)
        ])
    }

    public override func awakeFromNib() {
        super.awakeFromNib()

        button.setTitle(nil, for: .normal)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        alpha = 0
    }

    func show(message: String?) {
        button.setTitle(message, for: .normal)

        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
        }
    }

    func hideMessage() {
        UIView.animate(
            withDuration: 0.25,
            animations: { self.alpha = 0 },
            completion: { completed in
                if completed {
                    self.button.setTitle(nil, for: .normal)
                }
            })
    }

    @objc
    private func handleButtonAction() {
        hideMessage()
    }
}

private extension UIColor {
    static var errorBackgroundColor: UIColor {
        return UIColor(red: 0.99951404330000004, green: 0.41759261489999999, blue: 0.4154433012, alpha: 1)
    }
}

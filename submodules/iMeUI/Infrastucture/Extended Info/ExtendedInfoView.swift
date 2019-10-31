////
////  ExtendedInfoView.swift
////  TelegramUI
////
////  Created by Valeriy Mikholapov on 02/08/2019.
////  Copyright © 2019 Telegram. All rights reserved.
////
//
//import UIKit
//import Display
//import SwiftSignalKit
//import TelegramPresentationData
//import iMeLib
//
//protocol StatViewDescriptors {
//    static func allValues(_ presentationData: PresentationData) -> [StatView.Style]
//}
//
//final class ExtendedInfoView<Stat: StatViewDescriptors>: UIView, View, ThemeInitialisable {
//
//    // MARK: - State
//
//    private var presentationData: PresentationData
//
//    private var disposable: Disposable?
//
//    private var buttonTapCallback: (() -> Void)?
//    private var ratingTapCallback: ((Int) -> Void)?
//    private var linkTapCallback: (() -> Void)?
//    private var selectionTapCallback: (() -> Void)?
//
//    private var viewModel: ViewModel = .init()
//    private var sizeObservations: [NSKeyValueObservation] = []
//
//    // MARK: - Views
//
//    private let scrollView: UIScrollView = .init()
//
//    // Bot overview section views
//
//    private let avatarView: UIImageView = with(.init()) {
//        $0.layer.cornerRadius = 5.0
//        $0.clipsToBounds = true
//        $0.backgroundColor = .lightGray
//    }
//
//    private let titleLabel: InsetableLabel = with(.init()) {
//        $0.font = Font.medium(16)
//        $0.textInsets = .insets(top: -3)
//    }
//
//    private let tagCollectionView: TagCollectionView = with(.init()) {
//        $0.backgroundColor = .clear
//    }
//
//    // Stat section views
//
//    private let statContainer: UIView = .init()
//
//    private lazy var statViews: [StatView] = Stat.allValues(presentationData).map(StatView.init)
//
//    // Description section
//
//    private var descriptionContainer: UIView = .init()
//
//    private var bottomDescriptionConstraint: NSLayoutConstraint?
//    private let descriptionLabel: UILabel = with(.init()) {
//        $0.numberOfLines = 0
//        $0.font = Font.regular(12)
//    }
//
//    // Selection Section
//
//    private let selectionStackView: UIStackView = with(.init()) {
//        $0.axis = .vertical
//    }
//
//    private let selectionLabel: UILabel = with(.init()) {
//        $0.font = Font.regular(12)
//    }
//
//    private let firstSelectionButton: UIButton = with(.init()) {
//        $0.titleLabel?.font = Font.regular(12)
//        $0.contentHorizontalAlignment = .left
//        $0.isEnabled = false
//    }
//
//    private let secondSelectionButton: UIButton = with(.init()) {
//        $0.titleLabel?.font = Font.regular(12)
//        $0.contentHorizontalAlignment = .left
//    }
//
//    //
//
//    private let linkContainer: UIView = with(.init()) {
//        $0.backgroundColor = .clear
//    }
//
//    private let linkTitleLabel: UILabel = with(.init()) {
//        $0.font = Font.regular(12)
//    }
//
//    private let linkButton: UIButton = with(.init()) {
//        $0.titleLabel?.font = Font.regular(12)
//    }
//
//    // Rating section
//
//    private let ratingContainer: UIView = .init()
//
//    private let ratingTitleLabel: UILabel = with(.init()) {
//        $0.font = Font.medium(14.0)
//    }
//
//    private lazy var ratingView: RatingView = with(.init(presentationData: presentationData)) {
//        $0.starSize = 24
//        $0.spacing = 24
//        $0.numberOfStars = 5
//    }
//
//    // Buttons
//
//    private let actionButton: Button = with(.init(style: .shallow(with: .red))) {
//        $0.layer.cornerRadius = 5.0
//        $0.titleLabel?.font = Font.medium(16.0)
//    }
//
//    private let downloadButton: UIButton = with(.init()) {
//        $0.backgroundColor = .clear
//    }
//
//    private let downloadProgressView: DownloadProgressView = .init()
//
//    // MARK: - Lifecycle
//
//    init(presentationData: PresentationData) {
//        self.presentationData = presentationData
//        super.init(frame: .zero)
//        setup()
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("Not implemented!")
//    }
//
//    func set(viewModel: ViewModel) {
//        self.viewModel = viewModel
//
//        with(struct: viewModel) {
//            if let placeholder = $0.avatarStyle.placeholder { avatarView.set(placeholder: placeholder) }
//            avatarView.setImage(fromUrl: $0.avatar)
//            avatarView.layer.cornerRadius = $0.avatarStyle.isCircle
//                ? avatarView.bounds.width / 2
//                : 5
//
//            titleLabel.text = $0.title
//
//            tagCollectionView.replaceTags(with: $0.tags)
//
//            zip(statViews, $0.statViewsModels).forEach {
//                $0.set(viewModel: $1)
//            }
//
//            descriptionLabel.text = $0.description
//            linkButton.setTitle($0.link.map { "@\($0)" }, for: .normal)
//            linkContainer.isHidden = $0.link == nil
//
//            bottomDescriptionConstraint?.constant = $0.link == nil ? -14 : 0
//
//            ratingTitleLabel.text = $0.userRatingTitle
//            ratingView.rating = UInt($0.userRating)
//
//            if let selection = $0.selection {
//                selectionStackView.isHidden = false
//                selectionLabel.text = selection.title
//
//                firstSelectionButton.setTitle(selection.firstSelection.title, for: .normal)
//                firstSelectionButton.isEnabled = selection.firstSelection.isActive
//
//                if let secondSelection = selection.secondSelection {
//                    secondSelectionButton.isHidden = false
//                    secondSelectionButton.setTitle(secondSelection.title, for: .normal)
//                    secondSelectionButton.isEnabled = secondSelection.isActive
//                } else {
//                    secondSelectionButton.isHidden = true
//                }
//            } else {
//                selectionStackView.isHidden = true
//            }
//
//            ratingTapCallback = $0.ratingTapCallback
//            buttonTapCallback = $0.buttonTapCallback
//            linkTapCallback = $0.linkTapCallback
//            selectionTapCallback = $0.selectionTapCallback
//
//            let theme = presentationData.theme.iMe
//
//            switch $0.buttonModel {
//                case let .download(progressSignal):
//                    downloadProgressView.isHidden = false
//                    actionButton.isHidden = true
//
//                    downloadProgressView.set(progress: 0.0, animated: false)
//                    disposable = progressSignal.start(next: { [weak downloadProgressView] in
//                        downloadProgressView?.set(progress: $0, animated: true)
//                    })
//                case let .action(title: title):
//                    downloadProgressView.isHidden = true
//                    actionButton.isHidden = false
//
//                    actionButton.style = .filled(with: theme.accentColour, titleColour: theme.backgroundColour)
//                    actionButton.setTitle(title, for: .normal)
//                case let .toggle(title: title, isOn: isOn):
//                    downloadProgressView.isHidden = true
//                    actionButton.isHidden = false
//
//                    actionButton.style = .shallow(with: isOn ? theme.disableButtonColour : theme.accentColour)
//                    actionButton.setTitle(title, for: .normal)
//            }
//        }
//
//        updateConstraintsIfNeeded()
//    }
//
//    func update(presentationData: PresentationData) {
//        let theme = presentationData.theme.iMe
//
//        linkTitleLabel.text = presentationData.strings.ExtendedInfo_Link
//
//        with(theme) {
//            backgroundColor = $0.backgroundColour
//            avatarView.backgroundColor = $0.backgroundColour
//            statContainer.backgroundColor = $0.secondaryBackgroundColour
//            ratingContainer.backgroundColor = $0.secondaryBackgroundColour
//            tagCollectionView.tagBackgroundColour = $0.secondaryBackgroundColour
//
//            titleLabel.textColor = $0.titleTextColour
//            ratingTitleLabel.textColor = $0.secondaryTextColour
//            tagCollectionView.tagTextColour = $0.secondaryTextColour
//            descriptionLabel.textColor = $0.secondaryTextColour
//            selectionLabel.textColor = $0.secondaryTextColour
//            linkTitleLabel.textColor = $0.secondaryTextColour
//            linkButton.setTitleColor($0.accentColour, for: .normal)
//
//            [firstSelectionButton, secondSelectionButton].forEach {
//                $0.setTitleColor(theme.secondaryTextColour, for: .disabled)
//                $0.setTitleColor(theme.accentColour, for: .normal)
//            }
//
//            statViews.forEach {
//                $0.titleTextColour = theme.secondaryTextColour
//                $0.statTextColour = theme.titleTextColour
//            }
//
//            downloadProgressView.tintColor = theme.accentColour
//            switch actionButton.style {
//                case .filled:
//                    actionButton.style = .filled(with: $0.accentColour, titleColour: $0.backgroundColour)
//                case .shallow:
//                    actionButton.style = .shallow(with: $0.accentColour)
//            }
//        }
//    }
//
//    // MARK: - Customisation
//
//    private func setup() {
//        ratingView.ratingCallback = { [weak self] in
//            self?.ratingTapCallback?(Int($0))
//        }
//
//        let roundingClosure = { [weak self] (view: UIImageView, _: NSKeyValueObservedChange<CGRect>) -> Void in
//            guard
//                let viewModel = self?.viewModel,
//                viewModel.avatarStyle.isCircle
//            else { return }
//
//            view.layer.cornerRadius = view.bounds.width / 2
//        }
//
//        sizeObservations = [
//            avatarView.observe(\.bounds, changeHandler: roundingClosure),
//            avatarView.observe(\.frame, changeHandler: roundingClosure)
//        ]
//
//        actionButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
//        downloadButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
//        linkButton.addTarget(self, action: #selector(linkTapped), for: .touchUpInside)
//
//        [firstSelectionButton, secondSelectionButton].forEach {
//            $0.addTarget(self, action: #selector(selectionTapped), for: .touchUpInside)
//        }
//
//        setupHierarchy()
//        update(presentationData: presentationData)
//    }
//
//    private func setupHierarchy() {
//        let innerContainer = UIView()
//
//        let stackView = with(UIStackView()) {
//            $0.axis = .vertical
//            $0.alignment = .fill
//            $0.distribution = .fill
//        }
//
//        let overviewContainer = UIView()
//        overviewContainer.backgroundColor = .clear
//
//        let statStackView = with(UIStackView()) {
//            $0.axis = .horizontal
//            $0.alignment = .fill
//            $0.distribution = .fillEqually
//        }
//
//        let descriptionSubcontainer = with(UIStackView()) {
//            $0.axis = .vertical
//            $0.alignment = .fill
//            $0.spacing = 14
//        }
//
//        descriptionSubcontainer.backgroundColor = .clear
//
//        let lowerRatingContainer = UIView()
//
//        sv(
//            scrollView.sv(
//                innerContainer.sv(
//                    stackView.sva(
//                        overviewContainer.sv(
//                            avatarView,
//                            titleLabel,
//                            tagCollectionView
//                        ),
//                        statContainer.sv(
//                            statStackView.sva(
//                                statViews
//                            )
//                        ),
//                        descriptionContainer.sv(
//                            descriptionSubcontainer.sva(
//                                descriptionLabel,
//                                selectionStackView.sva(
//                                    selectionLabel,
//                                    firstSelectionButton,
//                                    secondSelectionButton
//                                )
//                            )
//                        ),
//                        linkContainer.sv(
//                            linkTitleLabel,
//                            linkButton
//                        ),
//                        ratingContainer.sv(
//                            ratingTitleLabel,
//                            lowerRatingContainer.sv(
//                                ratingView
//                            )
//                        )
//                    ),
//                    actionButton,
//                    downloadProgressView,
//                    downloadButton
//                )
//            )
//        )
//
//        layout(
//            layout(scrollView: scrollView, innerContainer: innerContainer, andMainStack: stackView),
//            layoutOverviewSection(in: overviewContainer),
//            layoutStatSection(in: statContainer, with: statStackView),
//            layoutDescriptionSection(in: descriptionSubcontainer),
//            layoutLinkButton(in: linkContainer),
//            layoutRatingSection(in: ratingContainer, lowerRatingContainer: lowerRatingContainer),
//            layoutButtons(in: innerContainer)
//        )
//    }
//
//    // MARK: - Layout
//
//    private func layout(scrollView: UIScrollView, innerContainer: UIView, andMainStack mainStack: UIStackView) -> [NSLayoutConstraint] {
//        var constraints = wrap(mainStack, innerContainer) {
//            $0.wireHorizontally(to: $1)
//                + $0.wire(to: $1, by: \.topAnchor)
//                + $0.wire(to: $1, by: \.bottomAnchor, insetedBy: -66)
//        }
//
//        constraints += wire(view: scrollView)
//        constraints += scrollView.wire(view: innerContainer)
//        constraints += innerContainer.wire(to: self, by: \.widthAnchor)
//
//        return constraints
//    }
//
//    private func layoutOverviewSection(in overviewContainer: UIView) -> [NSLayoutConstraint] {
//        var constraints = wrap(avatarView, overviewContainer) {[
//            $0.wire(to: $1, by: \.topAnchor, insetedBy: 20),
//            $0.wire(to: $1, by: \.leadingAnchor, insetedBy: 14),
//            $0.bottomAnchor.constraint(lessThanOrEqualTo: $1.bottomAnchor, constant: -20)
//        ]}
//
//        constraints += wrap(avatarView) {[
//            $0.wireRatio(),
//            $0.wireWidth(to: 72)
//        ]}
//
//        let anchorToAvatarView = { [avatarView] (v: UIView) -> NSLayoutConstraint in
//            avatarView.trailingAnchor.constraint(equalTo: v.leadingAnchor, constant: -16)
//        }
//
//        constraints += [titleLabel, tagCollectionView].map(anchorToAvatarView)
//
//        constraints += wrap(titleLabel) {[
//            $0.wire(to: overviewContainer, by: \.topAnchor, insetedBy: 20),
//            $0.wire(to: overviewContainer, by: \.trailingAnchor, insetedBy: -14)
//        ]}
//
//        constraints += wrap(tagCollectionView, overviewContainer) {[
//            $0.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 33),
//            $0.wire(to: $1, by: \.trailingAnchor, insetedBy: -16),
//            $0.wire(to: $1, by: \.bottomAnchor, insetedBy: -20),
//        ]}
//
//        return constraints
//    }
//
//    private func layoutStatSection(in statContainer: UIView, with statStackView: UIStackView) -> [NSLayoutConstraint] {
//        return statContainer.wire(view: statStackView)
//            + statContainer.heightAnchor.constraint(equalToConstant: 64)
//    }
//
//    private func layoutDescriptionSection(in descriptionSubcontainer: UIView) -> [NSLayoutConstraint] {
//        var constraints: [NSLayoutConstraint] = []
//
//        if let containerSuperview = descriptionContainer.superview {
//            constraints += descriptionContainer.wireHorizontally(to: containerSuperview)
//        }
//
//        constraints +=  wrap(descriptionContainer, descriptionSubcontainer) {
//            return $1.wireHorizontally(to: $0) + $1.wireVertically(to: $0, insetedBy: 14)
//        }
//
//        constraints += [descriptionLabel, selectionStackView]
//            .flatMap { $0.wireHorizontally(to: descriptionSubcontainer, insetedBy: 14) }
//
//        constraints += [firstSelectionButton, secondSelectionButton, selectionLabel]
//            .compactMap { $0.wireHeight(to: 22) }
//
//        return constraints
//    }
//
//
//    private func layoutLinkButton(in container: UIView) -> [NSLayoutConstraint] {
//        return [
//            linkTitleLabel.wire(to: container, by: \.topAnchor),
//            linkTitleLabel.wire(to: container, by: \.bottomAnchor, insetedBy: -14),
//            linkTitleLabel.wire(to: container, by: \.leadingAnchor, insetedBy: 14),
//            linkTitleLabel.wire(to: linkButton.leadingAnchor, by: \.trailingAnchor, insetedBy: -8),
//            linkButton.wire(to: container, by: \.topAnchor),
//            linkButton.wire(to: container, by: \.bottomAnchor, insetedBy: -14)
//        ]
//    }
//
//    private func layoutRatingSection(in ratingContainer: UIView, lowerRatingContainer: UIView) -> [NSLayoutConstraint] {
//        var constraints = [ratingContainer.heightAnchor.constraint(equalToConstant: 97)]
//
//        constraints += wrap(ratingTitleLabel, ratingContainer) {[
//            $0.wire(to: $1, by: \.leadingAnchor, insetedBy: 14),
//            $0.wire(to: $1, by: \.topAnchor, insetedBy: 14)
//        ]}
//
//        constraints += wrap(lowerRatingContainer, ratingContainer) {
//            $0.wireHorizontally(to: $1)
//                + $0.wire(to: $1, by: \.bottomAnchor)
//                + $0.topAnchor.constraint(equalTo: ratingTitleLabel.bottomAnchor)
//        }
//
//        constraints += wrap(ratingView, lowerRatingContainer) {[
//            $0.centerXAnchor.constraint(equalTo: $1.centerXAnchor),
//            $0.centerYAnchor.constraint(equalTo: $1.centerYAnchor),
//            $0.heightAnchor.constraint(equalToConstant: 24)
//        ]}
//
//        return constraints
//    }
//
//    private func layoutButtons(in container: UIView) -> [NSLayoutConstraint] {
//        var constraints = wrap(actionButton, container) {
//            $0.wireHorizontally(to: $1, insetedBy: 14)
//                + $0.wire(to: $1, by: \.bottomAnchor, insetedBy: -14)
//        }
//
//        constraints += wrap(downloadProgressView, container) {[
//            $0.wireRatio(),
//            $0.widthAnchor.constraint(equalToConstant: 38),
//            $0.wire(to: $1, by: \.bottomAnchor, insetedBy: -14),
//            $0.wire(to: $1, by: \.centerXAnchor)
//        ]}
//
//        constraints += wrapFlat(downloadButton, downloadProgressView, container) {[
//            $0.wireSize(to: $1),
//            [$0.wire(to: $2, by: \.bottomAnchor, insetedBy: -14),
//             $0.wire(to: $2, by: \.centerXAnchor)]
//        ]}
//
//        return constraints
//    }
//
//    // MARK: - Actions
//
//    @objc
//    private func buttonTapped() -> Void {
//        buttonTapCallback?()
//    }
//
//    @objc
//    private func linkTapped() -> Void {
//        linkTapCallback?()
//    }
//
//    @objc
//    private func selectionTapped() -> Void {
//        selectionTapCallback?()
//    }
//
//}
//
//// MARK: - Inner types
//
//extension ExtendedInfoView {
//
//    struct ViewModel: EmptyInitialisable {
//
//        enum ButtonModel {
//            case download(progressSignal: Signal<Float, NoError>)
//            case action(title: String)
//            case toggle(title: String, isOn: Bool)
//        }
//
//        struct Selection {
//            typealias Option = (title: String, isActive: Bool)
//
//            let title: String
//            let firstSelection: Option
//            let secondSelection: Option?
//        }
//
//        struct AvatarStyle {
//            let isCircle: Bool
//            let placeholder: Placeholder?
//        }
//
//        let avatar: URL?
//        let avatarStyle: AvatarStyle
//        let title: String
//        let tags: [String]
//
//        let statViewsModels: [StatView.ViewModel]
//
//        let description: String
//        let link: String?
//
//        let userRatingTitle: String
//        let userRating: Int
//
//        let selection: Selection?
//
//        let buttonModel: ButtonModel
//
//        let buttonTapCallback: (() -> Void)?
//        let ratingTapCallback: ((Int) -> Void)?
//        let linkTapCallback: (() -> Void)?
//        let selectionTapCallback: (() -> Void)?
//
//        init() {
//            self.init(avatar: nil)
//        }
//
//        init(
//            avatar: URL? = nil,
//            avatarStyle: AvatarStyle = .init(isCircle: false, placeholder: nil),
//            title: String = "",
//            tags: [String] = [],
//            statViewsModels: [StatView.ViewModel] = [],
//            description: String = "",
//            link: String? = nil,
//            userRatingTitle: String = "",
//            userRating: Int = 0,
//            selection: Selection? = nil,
//            buttonModel: ButtonModel = .action(title: ""),
//            buttonTapCallback: (() -> Void)? = nil,
//            ratingTapCallback: ((Int) -> Void)? = nil,
//            linkTapCallback: (() -> Void)? = nil,
//            selectionTapCallback: (() -> Void)? = nil
//        ) {
//            self.avatar = avatar
//            self.avatarStyle = avatarStyle
//            self.title = title
//            self.tags = tags
//            self.statViewsModels = statViewsModels
//            self.description = description
//            self.link = link
//            self.userRatingTitle = userRatingTitle
//            self.userRating = userRating
//            self.buttonModel = buttonModel
//            self.buttonTapCallback = buttonTapCallback
//            self.ratingTapCallback = ratingTapCallback
//            self.linkTapCallback = linkTapCallback
//            self.selection = selection
//            self.selectionTapCallback = selectionTapCallback
//        }
//    }
//
//}

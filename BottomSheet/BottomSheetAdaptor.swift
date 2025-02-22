//
//  BottomSheetAdaptor.swift
//  BottomSheet
//
//  Created by Nguyen, Michael on 2/21/25.
//
import SwiftUI
import UIKit

@objc
public enum BottomSheetCategory: Int {
    case info
    case error
    case confirm
    case help
    case success
    case location
    case calendar
    case call
    case phoneAlert
    case attachment
    case reminder
    case none

    func getUIImage() -> UIImage? {
        switch(self) {

        case .info:
            return UIImage(named: "categoryConfirm", in: .main, with: nil)

        case .error:
            return UIImage(named: "categoryError", in: .main, with: nil)

        case .confirm:
            return UIImage(named: "categoryConfirm", in: .main, with: nil)

        case .help:
            return UIImage(named: "categoryHelp", in: .main, with: nil)

        case .success:
            return UIImage(named: "categorySuccess", in: .main, with: nil)

        case .location:
            return UIImage(named: "topicLocation", in: .main, with: nil)

        case .calendar:
            return UIImage(named: "topicCalendar", in: .main, with: nil)

        case .call:
            return UIImage(named: "topicCall", in: .main, with: nil)

        case .attachment:
            return UIImage(named: "topicAttachment", in: .main, with: nil)

        case .reminder:
            return UIImage(named: "topicReminder", in: .main, with: nil)

        case .phoneAlert:
            return UIImage(named: "topicPhoneAlert", in: .main, with: nil)

        case .none:
            return nil
        }
    }
}


public enum BottomSheetDetents {
    case small
    case medium
    case large
    case fraction(CGFloat)

    @MainActor
    public func toDetent() -> UISheetPresentationController.Detent {
        switch self {
        case .small:
            return .custom(identifier: .init("small")) { context in
                return context.maximumDetentValue * 0.40
            }

        case .medium:
            return .medium()

        case .large:
            return .large()

        case .fraction(let value):
            return .custom(identifier: UISheetPresentationController.Detent.Identifier("fraction_\(value)")) {
                context in
                return context.maximumDetentValue * value
            }
        }
    }
}

public struct BottomSheetAdapter<Content: View>: UIViewControllerRepresentable {
    let title: String
    let category: BottomSheetCategory?
//    let detents: [BottomSheetDetents]
    let prefersGrabberVisible: Bool
    let isInteractiveDismissEnabled: Bool
    let cornerRadius: CGFloat
    let buttons: [BottomSheetButton]
    let onDismiss: (() -> Void)?
    let content: Content

    @State private var sheetID: UUID = UUID()
    @Binding var detents: Set<PresentationDetent> // 🔥 Use Binding
    @State private var totalHeight: CGFloat = 0 // Store the total height

    public init(
        title: String,
        category: BottomSheetCategory? = .info,
        detents: Binding<Set<PresentationDetent>>, // 🔥 Accept Binding
        prefersGrabberVisible: Bool = true,
        isInteractiveDismissEnabled: Bool = true,
        cornerRadius: CGFloat = 20,
        buttons: [BottomSheetButton] = [],
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.category = category
        self._detents = detents // 🔥 Store Binding
        self.prefersGrabberVisible = prefersGrabberVisible
        self.isInteractiveDismissEnabled = isInteractiveDismissEnabled
        self.cornerRadius = cornerRadius
        self.buttons = buttons
        self.onDismiss = onDismiss
        self.content = content()
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        let sheetView = BottomSheetView(
            title: title,
            category: category,
            buttons: buttons,
            dismissAction: onDismiss,
            content: content,
            detents: $detents,
            totalHeight: $totalHeight,
            onUpdateDetents: updateDetents(_:)
        )

        let hostingController = UIHostingController(rootView: sheetView)

        hostingController.modalPresentationStyle = .pageSheet
        
        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = $detents.wrappedValue.map { detent in
                    switch detent {
                    case .medium:
                        return .medium()
                    case .large:
                        return .large()
                    default:
                        return BottomSheetDetents.fraction(0.40).toDetent()
                    }
                }
            print ("Sheet detents: \(sheet.detents) \n\t \(sheet.detents.map(\.identifier))")
            sheet.prefersGrabberVisible = prefersGrabberVisible
            sheet.preferredCornerRadius = cornerRadius
            sheet.delegate = context.coordinator
        }

        hostingController.isModalInPresentation = !isInteractiveDismissEnabled

        return hostingController
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, UISheetPresentationControllerDelegate {
        var parent: BottomSheetAdapter

        init(_ parent: BottomSheetAdapter) {
            self.parent = parent
        }

        public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            parent.onDismiss?()
        }
    }

    var body: some View {
        VStack {
            Text("--------------- ")

            BottomSheetView(
                title: title + "sdfsjldf ",
                category: category,
                buttons: buttons,
                dismissAction: nil,
                content: content,
                detents: $detents, // Binding to be updated
                totalHeight: $totalHeight, // Binding for height
                onUpdateDetents: { newDetents in
                    DispatchQueue.main.async {
                        print ("new detents: \(newDetents)")
                        detents = newDetents // Ensure SwiftUI registers the update
                        sheetID = UUID() // 🔥 Force SwiftUI to refresh
                    }
                }
            )
            .id(sheetID) // 🔥 Forces a full re-evaluation of the view
            .presentationDetents(detents) // This ensures the sheet updates
            .presentationDragIndicator(prefersGrabberVisible ? .visible : .hidden)
            .interactiveDismissDisabled(!isInteractiveDismissEnabled)
            
            Spacer()
            Text("--------------- ")
        }
    }

    private func updateDetents(_ updatedDetents: Set<PresentationDetent>? = nil) {
        DispatchQueue.main.async {
            var updatedDetentsSet: Set<PresentationDetent> = [.medium]
            // Determine additional detents based on total height
            if totalHeight < UIScreen.main.bounds.height * 0.30 {
                updatedDetentsSet.insert(.fraction(0.30)) // Smallest fraction for compact UI
            } else if totalHeight < UIScreen.main.bounds.height * 0.6 {
                updatedDetentsSet.insert(.medium) // Use medium when reasonable
            } else if totalHeight < UIScreen.main.bounds.height * 0.8 {
                updatedDetentsSet.insert(.height(totalHeight)) // Use medium when reasonable
            } else {
                updatedDetentsSet.insert(.large) // Default to large for taller views
            }
//            DispatchQueue.main.async {
                detents = updatedDetentsSet
                sheetID = UUID()
//                print("New id: \(sheetID)")
            self.id(sheetID)
//            }
        }
    }
}

@available(iOS 16.0, *)
extension BottomSheetAdapter {

    /// Encapsulates presentation of the bottom sheet view.  Use this method to present the sheet from UIKIt
    /// - Parameter controller: UIViewController to present the sheet from
    public func present(in controller: UIViewController) {
        let hostingController = UIHostingController(rootView: self)
        hostingController.modalPresentationStyle = .pageSheet

        if let sheet = hostingController.sheetPresentationController {
//            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = prefersGrabberVisible
            sheet.preferredCornerRadius = cornerRadius
            sheet.prefersEdgeAttachedInCompactHeight = false // ✅ Prevents auto full-screen
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false // ✅ Prevents expansion on scroll

        }

        hostingController.isModalInPresentation = !isInteractiveDismissEnabled

        controller.present(hostingController, animated: true)
    }
}

//public extension UIViewController {
//    @objc func createDialog(title: String = "", message: String = "", category: BottomSheetCategory, buttons: [BottomSheetButton]? = [], controller: UIViewController) {
////        let dialog = self.createBottomSheetDialog(title: title, message: message, type: .info, buttons: buttons ?? []) {
////            Text(message)
////        }
////
////        dialog.present(in: controller)
//    }
//    func createBottomSheetDialog(
//        title: String,
//        category: BottomSheetCategory? = nil,
//        detents: Binding<Set<PresentationDetent>>, // 🔥 Accept Binding
//        prefersGrabberVisible: Bool = true,
//        isInteractiveDismissEnabled: Bool = true,
//        cornerRadius: CGFloat = 30,
//        buttons: [BottomSheetButton] = [],
//        @ViewBuilder content: @escaping () -> some View
//    ) -> UIViewController {
//        let hostingController = UIHostingController(
//            rootView: BottomSheetAdapter(
//                title: title,
//                category: category,
//                detents: detents, // ✅ Pass Binding
//                prefersGrabberVisible: prefersGrabberVisible,
//                isInteractiveDismissEnabled: isInteractiveDismissEnabled,
//                cornerRadius: cornerRadius,
//                buttons: buttons,
//                content: content
//            )
//        )
//
//        let sheetController = hostingController.sheetPresentationController
//        sheetController?.detents = detents.wrappedValue.map { detent in
//                switch detent {
//                case .medium:
//                    return .medium()
//                case .large:
//                    return .large()
//                default:
//                    return BottomSheetDetents.fraction(0.40).toDetent()
//                }
//            }
//        sheetController?.prefersGrabberVisible = prefersGrabberVisible
//        sheetController?.prefersScrollingExpandsWhenScrolledToEdge = false
//
//        return hostingController
//    }
//}

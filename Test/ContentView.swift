//
//  ContentView.swift
//  Test
//
//  Created by Kamil Suleymanov on 18.05.2024.
//

import SwiftUI

struct ContentView: View {
    @State var isPresented: Bool = false
    var body: some View {
        ZStack {
            Color.pink
                .ignoresSafeArea()
            Button {
                isPresented.toggle()
            } label: {
                Text("Tap me!")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
            }
        }
        .sheetWithDetents(
            isPresented: $isPresented,
            detents: [
                .medium(),
                .customDetent(height: 200)
            ],
             showCloseButton: true
        ) {
            Group {
                Text("Create")
                    .bold()
                +
                Text("with")
                +
                Text("Swift")
                    .bold()
            }
            .font(.title)
        }
    }
}

#Preview {
    ContentView()
}

struct sheetWithDetentsViewModifier<SwiftUIContent>: ViewModifier where SwiftUIContent: View {
    @Binding var isPresented: Bool
    let detents: [UISheetPresentationController.Detent]
    let showCloseButton: Bool
    let swiftUIContent: SwiftUIContent

    init(
        isPresented: Binding<Bool>,
        detents: [UISheetPresentationController.Detent] = [.medium()],
        showCloseButton: Bool = false,
        content: () -> SwiftUIContent
    ) {
        self._isPresented = isPresented
        self.swiftUIContent = content()
        self.detents = detents
        self.showCloseButton = showCloseButton
    }

    func body(content: Content) -> some View {
        ZStack {
            SheetPresentationForSwiftUI($isPresented, detents: detents, showCloseButton: showCloseButton) {
                swiftUIContent
            }
            .fixedSize()
            content
        }
    }
}

extension UISheetPresentationController.Detent {
    static func customDetent(height: CGFloat) -> UISheetPresentationController.Detent {
        return .custom(identifier: .medium) { context in
            return height
        }
    }
}

extension View {
    func sheetWithDetents<Content>(
        isPresented: Binding<Bool>,
        detents: [UISheetPresentationController.Detent],
        showCloseButton: Bool = false,
        content: @escaping () -> Content) -> some View where Content : View {
            modifier(
                sheetWithDetentsViewModifier(
                    isPresented: isPresented,
                    detents: detents,
                    showCloseButton: showCloseButton,
                    content: content)
            )
        }
}

struct SheetPresentationForSwiftUI<Content>: UIViewRepresentable where Content: View {
    @Binding var isPresented: Bool
    let detents: [UISheetPresentationController.Detent]
    let showCloseButton: Bool
    let content: Content
    
    init(
        _ isPresented: Binding<Bool>,
        detents: [UISheetPresentationController.Detent] = [.medium()],
        showCloseButton: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.detents = detents
        self.showCloseButton = showCloseButton
        self.content = content()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let viewController = UIViewController()
        let hostingController = UIHostingController(rootView: content)
        viewController.addChild(hostingController)
        viewController.view.addSubview(hostingController.view)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.leftAnchor.constraint(equalTo: viewController.view.leftAnchor).isActive = true
        hostingController.view.topAnchor.constraint(equalTo: viewController.view.topAnchor).isActive = true
        hostingController.view.rightAnchor.constraint(equalTo: viewController.view.rightAnchor).isActive = true
        hostingController.view.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor).isActive = true
        hostingController.didMove(toParent: viewController)

        if let sheetController = viewController.presentationController as? UISheetPresentationController {
            sheetController.detents = detents
            sheetController.prefersGrabberVisible = true
            sheetController.prefersScrollingExpandsWhenScrolledToEdge = false
            sheetController.largestUndimmedDetentIdentifier = .medium
            sheetController.preferredCornerRadius = 20
        }

        if showCloseButton {
            let closeButton = UIButton(type: .system)
            closeButton.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
            closeButton.addTarget(context.coordinator, action: #selector(context.coordinator.closeButtonTapped), for: .touchUpInside)
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            viewController.view.addSubview(closeButton)

            NSLayoutConstraint.activate([
                closeButton.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor, constant: 10),
                closeButton.leadingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -35)
            ])
        }

        viewController.presentationController?.delegate = context.coordinator

        if isPresented {
            uiView.window?.rootViewController?.present(viewController, animated: true)
        } else {
            uiView.window?.rootViewController?.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }

    class Coordinator: NSObject, UISheetPresentationControllerDelegate {
        @Binding var isPresented: Bool

        init(isPresented: Binding<Bool>) {
            self._isPresented = isPresented
        }

        @objc func closeButtonTapped() {
            isPresented = false
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            isPresented = false
        }
    }
}

//
//  smpl_widgetsApp.swift
//  smpl-widgets
//
//  Created by Nitish on 11/11/25.
//

import SwiftUI

@main
struct smpl_widgetsApp: App {
	@State private var isRedirecting = false

	var body: some Scene {
		WindowGroup {
			ZStack {
				if !isRedirecting {
					ContentView()
				}

				if isRedirecting {
					Color(.systemBackground).ignoresSafeArea()
					ProgressView()
				}
			}
			.onOpenURL { url in
				if url.absoluteString.contains("://") {
					isRedirecting = true
					UIApplication.shared.open(url)
				}
			}
		}
	}
}

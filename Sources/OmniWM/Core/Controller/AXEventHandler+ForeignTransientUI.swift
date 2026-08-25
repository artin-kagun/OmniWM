// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/BarutSRB/OmniWM

import Foundation

@MainActor
extension AXEventHandler {
    func protectForeignTransientUI(
        _ token: WindowToken,
        requiresFrontmostApplication: Bool
    ) {
        guard let controller else { return }
        if requiresFrontmostApplication {
            guard frontmostApplicationPIDProvider() == token.pid else { return }
        }
        guard protectedForeignTransientUITokens.insert(token).inserted else { return }

        controller.focusPolicyEngine.beginLease(
            owner: .foreignTransientUI,
            reason: WindowAdmissionRejectionReason.nonRenderableTransientSurface.rawValue,
            suppressesFocusFollowsMouse: true,
            duration: nil
        )
    }

    func releaseForeignTransientUI(windowId: Int) {
        releaseForeignTransientUI { $0.windowId == windowId }
    }

    func releaseForeignTransientUI(pid: pid_t) {
        releaseForeignTransientUI { $0.pid == pid }
    }

    func clearForeignTransientUIProtection() {
        guard !protectedForeignTransientUITokens.isEmpty else { return }
        protectedForeignTransientUITokens.removeAll()
        controller?.focusPolicyEngine.endLease(owner: .foreignTransientUI)
    }

    private func releaseForeignTransientUI(
        matching predicate: (WindowToken) -> Bool
    ) {
        let retainedTokens = Set(protectedForeignTransientUITokens.filter { !predicate($0) })
        guard retainedTokens.count != protectedForeignTransientUITokens.count else { return }
        protectedForeignTransientUITokens = retainedTokens
        if retainedTokens.isEmpty {
            controller?.focusPolicyEngine.endLease(owner: .foreignTransientUI)
        }
    }
}

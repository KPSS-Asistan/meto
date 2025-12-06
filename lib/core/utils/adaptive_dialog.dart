import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Platform-adaptive dialog utilities
/// iOS'ta Cupertino, Android'de Material görünümü sağlar
class AdaptiveDialog {
  AdaptiveDialog._();

  /// Platform-adaptive alert dialog
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDangerous = false,
  }) {
    final isIOS = Platform.isIOS;
    
    if (isIOS) {
      return showCupertinoDialog<T>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            if (cancelText != null)
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(ctx);
                  onCancel?.call();
                },
                child: Text(cancelText),
              ),
            if (confirmText != null)
              CupertinoDialogAction(
                isDestructiveAction: isDangerous,
                onPressed: () {
                  Navigator.pop(ctx);
                  onConfirm?.call();
                },
                child: Text(confirmText),
              ),
          ],
        ),
      );
    } else {
      return showDialog<T>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title),
          content: Text(content),
          actions: [
            if (cancelText != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onCancel?.call();
                },
                child: Text(cancelText),
              ),
            if (confirmText != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onConfirm?.call();
                },
                style: isDangerous
                    ? TextButton.styleFrom(foregroundColor: Colors.red)
                    : null,
                child: Text(confirmText),
              ),
          ],
        ),
      );
    }
  }

  /// Platform-adaptive confirmation dialog (returns bool)
  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'Onayla',
    String cancelText = 'İptal',
    bool isDangerous = false,
  }) async {
    final isIOS = Platform.isIOS;
    
    if (isIOS) {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(cancelText),
            ),
            CupertinoDialogAction(
              isDestructiveAction: isDangerous,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmText),
            ),
          ],
        ),
      );
    } else {
      return showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: isDangerous
                  ? TextButton.styleFrom(foregroundColor: Colors.red)
                  : null,
              child: Text(confirmText),
            ),
          ],
        ),
      );
    }
  }

  /// Platform-adaptive loading dialog
  static void showLoading(BuildContext context, {String? message}) {
    final isIOS = Platform.isIOS;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isIOS)
                  const CupertinoActivityIndicator(radius: 16)
                else
                  const CircularProgressIndicator(),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(message),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Platform-adaptive action sheet (bottom)
  static Future<T?> showActionSheet<T>({
    required BuildContext context,
    String? title,
    String? message,
    required List<AdaptiveAction<T>> actions,
    String cancelText = 'İptal',
  }) {
    final isIOS = Platform.isIOS;
    
    if (isIOS) {
      return showCupertinoModalPopup<T>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: title != null ? Text(title) : null,
          message: message != null ? Text(message) : null,
          actions: actions.map((action) => CupertinoActionSheetAction(
            isDestructiveAction: action.isDestructive,
            onPressed: () => Navigator.pop(ctx, action.value),
            child: Text(action.label),
          )).toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(cancelText),
          ),
        ),
      );
    } else {
      return showModalBottomSheet<T>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ...actions.map((action) => ListTile(
                title: Text(
                  action.label,
                  style: action.isDestructive
                      ? const TextStyle(color: Colors.red)
                      : null,
                ),
                leading: action.icon != null ? Icon(action.icon) : null,
                onTap: () => Navigator.pop(ctx, action.value),
              )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    }
  }
}

/// Action item for action sheets
class AdaptiveAction<T> {
  final String label;
  final T value;
  final IconData? icon;
  final bool isDestructive;

  const AdaptiveAction({
    required this.label,
    required this.value,
    this.icon,
    this.isDestructive = false,
  });
}

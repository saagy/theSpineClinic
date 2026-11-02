import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/operation_feedback.dart';
import '../document_upload_controller.dart';
import '../document_upload_state.dart';

class DocumentUploadFeedback extends ConsumerWidget {
  const DocumentUploadFeedback({super.key, required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentUploadControllerProvider(patientId));
    if (!state.isLoading && !state.hasFailures) return const SizedBox.shrink();
    final controller = ref.read(documentUploadControllerProvider(patientId).notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OperationFeedback(
            message: state.isLoading
                ? AppStrings.uploadingDocuments
                : AppStrings.uploadNeedsAttention,
            detail: state.isLoading
                ? state.active?.fileName ?? AppStrings.keepPageOpen
                : AppStrings.documentsAttached(state.completed, state.files.length),
            isBusy: state.isLoading,
            showUploadProgress: true,
            isError: !state.isLoading,
          ),
          for (int i = 0; i < state.files.length; i++)
            if (state.files[i].status == DocumentUploadStatus.failed)
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
                      child: Text(
                        '${state.files[i].fileName}\n${state.files[i].isUnconfirmed ? AppStrings.uploadUnconfirmed : AppStrings.fromKey(state.files[i].error!.userMessageKey)}',
                        style: AppTextStyles.caption.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                  if (!state.files[i].isUnconfirmed && !state.isLoading)
                    IconButton(
                      tooltip: AppStrings.removeFailedFile,
                      onPressed: () => controller.removeRejected(i),
                      icon: const Icon(Icons.close, size: AppSizes.iconSmall),
                      constraints: const BoxConstraints.tightFor(
                        width: AppSizes.tappableMin,
                        height: AppSizes.tappableMin,
                      ),
                    ),
                ],
              ),
          if (state.hasFailures && !state.isLoading)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: controller.retry,
                style: TextButton.styleFrom(minimumSize: const Size.square(AppSizes.tappableMin)),
                child: const Text(AppStrings.retryUploads, style: AppTextStyles.captionBold),
              ),
            ),
        ],
      ),
    );
  }
}

part of 'profile_editor_form.dart';

extension _ProfileEditorView on _ProfileEditorFormState {
  Widget _content(BuildContext context, bool isSaving) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
        child: Text(
          widget.passwordOnly
              ? AppStrings.profilePasswordHelp
              : AppStrings.profileDetailsHelp,
          style: AppTextStyles.bodySecondary.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      const SizedBox(height: AppSizes.p16),
      if (widget.passwordOnly)
        _passwordFields(isSaving)
      else ...[
        FormSection(
          title: AppStrings.personalDetails,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _name,
                labelText: AppStrings.fullName,
                enabled: !isSaving,
                autofillHints: const [AutofillHints.name],
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (String? value) =>
                    value == null || value.trim().isEmpty
                    ? AppStrings.fullNameRequired
                    : null,
              ),
              const SizedBox(height: AppSizes.p20),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints box) {
                  final Widget email = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _email,
                        labelText: AppStrings.email,
                        enabled: !isSaving,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.emailRequired;
                          }
                          return RegExp(
                                r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                              ).hasMatch(value.trim())
                              ? null
                              : AppStrings.emailInvalid;
                        },
                      ),
                      const SizedBox(height: AppSizes.p8),
                      Text(
                        AppStrings.profileEmailHelp,
                        style: AppTextStyles.caption.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                  final Widget phone = AppTextField(
                    controller: _phone,
                    labelText: AppStrings.profilePhoneLabel,
                    enabled: !isSaving,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _save(),
                  );
                  if (box.maxWidth >= AppSizes.formPairBreakpoint &&
                      MediaQuery.textScalerOf(context).scale(1) <=
                          AppSizes.formPairMaxTextScale) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: email),
                        const SizedBox(width: AppSizes.p20),
                        Expanded(child: phone),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      email,
                      const SizedBox(height: AppSizes.p20),
                      phone,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.p24),
        FormSection(
          title: AppStrings.accountSecurity,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            minTileHeight: AppSizes.tappableMin,
            title: const Text(
              AppStrings.changePassword,
              style: AppTextStyles.bodyMedium,
            ),
            subtitle: const Text(
              AppStrings.profileSecurityHelp,
              style: AppTextStyles.caption,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: isSaving
                ? null
                : () => context.push(AppRoutes.profilePassword),
          ),
        ),
      ],
    ],
  );

  Widget _passwordFields(bool isSaving) => FormSection(
    title: AppStrings.accountSecurity,
    child: Column(
      children: [
        AppTextField(
          controller: _password,
          labelText: AppStrings.newPasswordHint,
          enabled: !isSaving,
          isPassword: true,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.next,
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              return AppStrings.passwordRequired;
            }
            return value.length < 8 ? AppStrings.passwordMinLength : null;
          },
        ),
        const SizedBox(height: AppSizes.p20),
        AppTextField(
          controller: _confirm,
          labelText: AppStrings.confirmPassword,
          enabled: !isSaving,
          isPassword: true,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _save(),
          validator: (String? value) =>
              value != _password.text ? AppStrings.passwordsDoNotMatch : null,
        ),
      ],
    ),
  );
}

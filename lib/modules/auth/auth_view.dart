import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:otraku/common/utils/consts.dart';
import 'package:otraku/common/utils/options.dart';
import 'package:otraku/common/utils/api.dart';
import 'package:otraku/common/utils/routing.dart';
import 'package:otraku/common/widgets/layouts/top_bar.dart';
import 'package:otraku/common/widgets/loaders/loaders.dart';
import 'package:otraku/common/widgets/overlays/dialogs.dart';
import 'package:otraku/common/widgets/overlays/toast.dart';

class AuthView extends StatefulWidget {
  const AuthView();

  @override
  AuthViewState createState() => AuthViewState();
}

class AuthViewState extends State<AuthView> {
  StreamSubscription<String>? _sub;
  bool _loading = false;

  void _verify(int account) {
    setState(() => _loading = true);

    Api.logIn(account).then((loggedIn) {
      if (!loggedIn) {
        setState(() => _loading = false);
        return;
      }

      Options().selectedAccount = account;
      context.go(Routes.home());
    });
  }

  Future<void> _requestAccessToken(int account) async {
    setState(() => _loading = true);

    // Prepare to receive an authentication token.
    _clearStreamSubscription();
    _sub = AppLinks().stringLinkStream.listen((link) async {
      final start = link.indexOf('=') + 1;
      final middle = link.indexOf('&');
      final end = link.lastIndexOf('=') + 1;

      if (start < 1 || middle < 1 || end < 1) {
        setState(() => _loading = false);
        showPopUp(
          context,
          const ConfirmationDialog(
            content: 'Needed data is missing',
            title: 'Faulty response',
          ),
        );
        return;
      }

      final token = link.substring(start, middle);
      final expiration = int.tryParse(link.substring(end)) ?? -1;

      if (token.isEmpty || expiration < 0) {
        setState(() => _loading = false);
        showPopUp(
          context,
          const ConfirmationDialog(
            content: 'Could not parse data',
            title: 'Faulty response',
          ),
        );
        return;
      }

      await Api.register(account, token, expiration);
      _clearStreamSubscription();
      _verify(account);
    });

    // Redirect to the browser for authentication.
    final ok = await Toast.launch(
      context,
      'https://anilist.co/api/v2/oauth/authorize?client_id=3535&response_type=token',
    );

    if (!ok) setState(() => _loading = false);
  }

  void _clearStreamSubscription() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  void initState() {
    super.initState();
    if (Options().account != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _verify(Options().account!),
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: Loader()),
            if (_sub != null) ...[
              const SizedBox(height: 10),
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  _clearStreamSubscription();
                  setState(() => _loading = false);
                },
              ),
            ],
          ],
        ),
      );
    }

    final available0 = Options().isAvailableAccount(0);
    final available1 = Options().isAvailableAccount(1);

    return Scaffold(
      body: Container(
        alignment: Alignment.bottomCenter,
        padding: Consts.padding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Consts.layoutMedium),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Otraku for AniList',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              Container(
                padding: Consts.padding,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: Consts.borderRadiusMin,
                ),
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Primary Account',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (available0) ...[
                          const SizedBox(height: 5),
                          Text(
                            Options().idOf(0)?.toString() ?? '',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    if (available0)
                      TopBarIcon(
                        icon: Ionicons.close_circle_outline,
                        tooltip: 'Remove Account',
                        onTap: () => showPopUp(
                          context,
                          ConfirmationDialog(
                            title: 'Remove Account?',
                            mainAction: 'Yes',
                            secondaryAction: 'No',
                            onConfirm: () => Api.removeAccount(0)
                                .then((_) => setState(() {})),
                          ),
                        ),
                      ),
                    TopBarIcon(
                      icon: Ionicons.enter_outline,
                      tooltip: available0 ? 'Log In' : 'Connect',
                      onTap: () =>
                          available0 ? _verify(0) : _requestAccessToken(0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: Consts.padding,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: Consts.borderRadiusMin,
                ),
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secondary Account',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (available1) ...[
                          const SizedBox(height: 5),
                          Text(
                            Options().idOf(1)?.toString() ?? '',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    if (available1)
                      TopBarIcon(
                        icon: Ionicons.close_circle_outline,
                        tooltip: 'Remove Account',
                        onTap: () => showPopUp(
                          context,
                          ConfirmationDialog(
                            title: 'Remove Account?',
                            mainAction: 'Yes',
                            secondaryAction: 'No',
                            onConfirm: () => Api.removeAccount(1)
                                .then((_) => setState(() {})),
                          ),
                        ),
                      ),
                    TopBarIcon(
                      icon: Ionicons.enter_outline,
                      tooltip: available1 ? 'Log In' : 'Connect',
                      onTap: () =>
                          available1 ? _verify(1) : _requestAccessToken(1),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Before connecting another account, you should log out from the first one in the browser.',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

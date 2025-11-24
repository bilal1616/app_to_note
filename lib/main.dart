// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/repositories/notes_repository.dart';

// Cubits
import 'presentation/cubits/auth/auth_cubit.dart';
import 'presentation/cubits/notes/notes_cubit.dart';
import 'presentation/cubits/trash/trash_cubit.dart';
import 'presentation/cubits/offline/offline_queqe_cubit.dart';

// Pages
import 'presentation/pages/auth/auth_gate.dart';
import 'presentation/pages/auth/register_page.dart';
import 'presentation/pages/notes/notes_page.dart';
import 'presentation/pages/notes/trash_page.dart';

// Connectivity binder
import 'presentation/core/connectivity_binder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
  );

  final dir = await getApplicationDocumentsDirectory();
  HydratedBloc.storage = await HydratedStorage.build(storageDirectory: dir);

  runApp(const AppToNote());
}

class AppToNote extends StatelessWidget {
  const AppToNote({super.key});

  @override
  Widget build(BuildContext context) {
    // !!! NotesRepository client parametresi ZORUNLU
    final repo = NotesRepository(Supabase.instance.client);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => OfflineQueueCubit(repo)),
        BlocProvider(
          create: (ctx) =>
              NotesCubit(repo, ctx.read<OfflineQueueCubit>())..bootstrap(),
        ),
      ],
      child: ConnectivityBinder(repo: repo, child: const _App()),
    );
  }
}

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App To Note',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const AuthGate(),
      routes: {
        '/notes': (_) => const NotesPage(),
        '/trash': (_) => BlocProvider(
          create: (ctx) =>
              TrashCubit(NotesRepository(Supabase.instance.client))
                ..bootstrap(),
          child: const TrashPage(),
        ),
        '/register': (_) => const RegisterPage(),
      },
    );
  }
}

// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tourify_app/app.dart';
import 'package:tourify_app/core/analytics/analytics_repository.dart';
import 'package:tourify_app/core/notifiers/auth_notifier.dart';
import 'package:tourify_app/features/account/model/account_repository.dart';
import 'package:tourify_app/features/booking/model/booking_repository.dart';
import 'package:tourify_app/features/booking/model/booking_repository_impl.dart';
import 'package:tourify_app/features/booking/presenter/trips_presenter.dart';
import 'package:tourify_app/features/account/presenter/account_presenter.dart';
import 'package:tourify_app/features/auth/model/auth_repository.dart';
import 'package:tourify_app/features/auth/model/auth_repository_impl.dart';
import 'package:tourify_app/features/auth/presenter/auth_presenter.dart';
import 'package:tourify_app/features/home/model/home_repository.dart';
import 'package:tourify_app/features/home/model/recent_tour_storage.dart';
import 'package:tourify_app/features/home/presenter/home_presenter.dart';
import 'package:tourify_app/features/notifications/model/notification_repository.dart';
import 'package:tourify_app/features/notifications/model/notification_repository_impl.dart';
import 'package:tourify_app/features/notifications/presenter/notification_presenter.dart';
import 'package:tourify_app/features/tour/model/tour_repository.dart';
import 'package:tourify_app/features/tour/model/tour_repository_impl.dart';
import 'package:tourify_app/features/cart/model/cart_repository.dart';
import 'package:tourify_app/features/cart/model/cart_repository_impl.dart';
import 'package:tourify_app/features/cart/presenter/cart_presenter.dart';
import 'package:tourify_app/features/wishlist/model/wishlist_repository.dart';
import 'package:tourify_app/features/wishlist/model/wishlist_repository_impl.dart';
import 'package:tourify_app/features/wishlist/presenter/wishlist_presenter.dart';

final authNotifier = AuthNotifier();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await authNotifier.init();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    MultiProvider(
      providers: [
        // Repositories
        Provider<AuthRepository>(create: (_) => AuthRepositoryImpl()),
        Provider<TourRepository>(create: (_) => TourRepositoryImpl()),
        Provider<HomeRepository>(create: (_) => HomeRepositoryImpl()),
        Provider<RecentTourStorage>(create: (_) => RecentTourStorage()),
        Provider<AnalyticsRepository>(create: (_) => AnalyticsRepository()),
        Provider<WishlistRepository>(create: (_) => WishlistRepositoryImpl()),
        Provider<AccountRepository>(create: (_) => AccountRepositoryImpl()),
        Provider<CartRepository>(create: (_) => CartRepositoryImpl()),
        Provider<BookingRepository>(create: (_) => BookingRepositoryImpl()),
        Provider<NotificationRepository>(
          create:
              (context) => NotificationRepositoryImpl(
                bookingRepository: context.read<BookingRepository>(),
              ),
        ),

        // Notifiers & Presenters
        ChangeNotifierProvider.value(value: authNotifier),
        ChangeNotifierProvider(
          create:
              (context) => AuthPresenter(
                context.read<AuthRepository>(),
                context.read<AuthNotifier>(),
              ),
        ),
        ChangeNotifierProvider(
          create:
              (context) => HomePresenter(
                context.read<HomeRepository>(),
                context.read<AnalyticsRepository>(),
                recentStorage: context.read<RecentTourStorage>(),
              ),
        ),
        ChangeNotifierProvider(
          create:
              (context) => NotificationPresenter(
                context.read<NotificationRepository>(),
              ),
        ),
        ChangeNotifierProvider(
          create:
              (context) =>
                  WishlistPresenter(context.read<WishlistRepository>()),
        ),
        ChangeNotifierProvider(
          create:
              (context) => AccountPresenter(
                context.read<AuthRepository>(),
                context.read<AuthNotifier>(),
                context.read<AccountRepository>(),
              ),
        ),
        ChangeNotifierProvider(
          create: (context) => CartPresenter(context.read<CartRepository>()),
        ),
        ChangeNotifierProvider(
          create:
              (context) => TripsPresenter(context.read<BookingRepository>()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

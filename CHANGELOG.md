## 1.0.0

* **[Major Architecture Refactoring]** Completely migrated the package entirely to pure Clean Architecture standards.
* Strictly split structural concepts into `domain/` and `data/` and `presentation/` layers. 
* Migrated from ad-hoc scripting to strict `UseCases` (`InitIapUseCase`, `BuyProductUseCase`, etc.) enabling greater scale and easier component access without the `IapManager` restriction.
* Formatted core exceptions down strictly standard Dart implementations (`IapException`, `IapFailure`) resolving external package footprint to `zero` (No `dartz`).
* Revamped OS streaming events with the fail-safe flow. Streams now strictly monitor OS-level errors (`User Canceled`, Pending logic bypass, restore duplication handling) guaranteeing no dropped transactions if an app dies midway.
* Exposed `enableMockMode: true` in the manager init config allowing developers to seamlessly test their UI entirely using the all-new `FakeIapRemoteDataSource` without ever touching real devices or getting configuration bugs on iOS Simulator.
* **[Doc Update]** Refreshed README and SETUP.

## 0.0.1

* Initial release. Wrapped standard `in_app_purchase` features.

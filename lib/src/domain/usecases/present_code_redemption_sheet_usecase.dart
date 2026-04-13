import '../../core/usecases/usecase.dart';
import '../repositories/iap_repository.dart';

class PresentCodeRedemptionSheetUseCase implements UseCase<void, NoParams> {
  final IapRepository repository;

  PresentCodeRedemptionSheetUseCase(this.repository);

  @override
  Future<void> call(NoParams params) async {
    return await repository.presentCodeRedemptionSheet();
  }
}

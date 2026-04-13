import '../../core/usecases/usecase.dart';
import '../repositories/iap_repository.dart';

/// UseCase yêu cầu hệ thống (OS) hiển thị màn hình nhập mã khuyến mãi (Offer Code) (chỉ hỗ trợ trên thiết bị Apple từ iOS 14).
class PresentCodeRedemptionSheetUseCase implements UseCase<void, NoParams> {
  final IapRepository repository;

  PresentCodeRedemptionSheetUseCase(this.repository);

  @override
  Future<void> call(NoParams params) async {
    return await repository.presentCodeRedemptionSheet();
  }
}

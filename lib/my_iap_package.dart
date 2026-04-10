/// A lightweight, framework-agnostic wrapper around `in_app_purchase`.
/// Thiết kế tuân theo Clean Architecture (Entities, Repositories, UseCases, Manager).
library;

// Core (chỉ export các thứ thuộc định nghĩa lỗi nếu user muốn catch bên ngoài)
export 'src/core/error/exceptions.dart';
export 'src/core/error/failures.dart';

// Domain Entities
export 'src/domain/entities/iap_product_type.dart';
export 'src/domain/entities/iap_product_config.dart';
export 'src/domain/entities/user_entitlement.dart';
export 'src/domain/entities/iap_product.dart';
export 'src/domain/entities/promotional_offer_signature.dart';

// Domain Repositories (Dành cho custom validation nếu có)
export 'src/domain/repositories/receipt_validator.dart';

// Presentation Manager
export 'src/presentation/manager/iap_manager.dart';

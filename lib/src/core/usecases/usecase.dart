/// Base UseCase interface cho các use case không trả về kết quả (thực thi hành động).
abstract class UseCase<T, Params> {
  Future<T> call(Params params);
}

/// Base UseCase cho loại trả lại cấu trúc dạng stream.
abstract class StreamUseCase<T, Params> {
  Stream<T> call(Params params);
}

/// Đại diện cho tham số rỗng (khi không cần truyền params vào usecase).
class NoParams {}

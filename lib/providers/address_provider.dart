import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import '../data/models/address_model.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

class AddressState {
  final List<AddressModel> addresses;
  final AddressModel? selectedAddress;
  final bool isLoading;
  final String? errorMessage;

  AddressState({
    this.addresses = const [],
    this.selectedAddress,
    this.isLoading = false,
    this.errorMessage,
  });

  AddressState copyWith({
    List<AddressModel>? addresses,
    AddressModel? selectedAddress,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AddressState(
      addresses: addresses ?? this.addresses,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AddressNotifier extends StateNotifier<AddressState> {
  final Ref ref;

  AddressNotifier(this.ref) : super(AddressState()) {
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    final user = ref.read(authProvider).user;
    final userId = user?.id?.toString() ?? '1';

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('${ApiEndpoints.userAddresses}/$userId');
      final data = res.data;

      if (data['success'] == true && data['addresses'] != null) {
        final list = (data['addresses'] as List)
            .map((a) => AddressModel.fromJson(a as Map<String, dynamic>))
            .toList();
        final defaultAddr = list.firstWhere((a) => a.isDefault, orElse: () => list.isNotEmpty ? list.first : AddressModel(id: 0, name: '', phone: '', address: '', pincode: ''));
        state = state.copyWith(
          addresses: list,
          selectedAddress: defaultAddr.id != 0 ? defaultAddr : null,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void selectAddress(AddressModel address) {
    state = state.copyWith(selectedAddress: address);
  }

  Future<bool> addAddress(AddressModel address) async {
    final user = ref.read(authProvider).user;
    final payload = address.toJson();
    payload['user_id'] = user?.id ?? 1;

    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post(ApiEndpoints.addresses, data: payload);
      if (res.data['success'] == true) {
        await fetchAddresses();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateAddress(AddressModel address) async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.put('${ApiEndpoints.addresses}/${address.id}', data: address.toJson());
      if (res.data['success'] == true) {
        await fetchAddresses();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAddress(dynamic id) async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.delete('${ApiEndpoints.addresses}/$id');
      if (res.data['success'] == true) {
        final list = state.addresses.where((a) => a.id != id).toList();
        state = state.copyWith(addresses: list);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

final addressProvider = StateNotifierProvider<AddressNotifier, AddressState>((ref) {
  return AddressNotifier(ref);
});


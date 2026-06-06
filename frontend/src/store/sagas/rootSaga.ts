import { all, fork } from "redux-saga/effects";
import { catalogSaga } from "../../features/shop/catalog/catalogSaga";
import { customersSaga } from "../../features/admin/customers/customersSaga";
import { productsSaga } from "../../features/admin/products/productsSaga";
import { reviewsSaga } from "../../features/admin/reviews/reviewsSaga";
import { ordersSaga } from "../../features/admin/orders/ordersSaga";
import { adminCartsSaga, userCartSaga } from "../../features/admin/cart/cartSaga";
import { paymentsSaga } from "../../features/admin/payments/paymentsSaga";
import { settingsSaga } from "../../features/admin/settings/settingsSaga";
import { authSaga } from "../../features/auth/authSaga";

export function* rootSaga() {
  yield all([fork(catalogSaga), fork(customersSaga), fork(productsSaga), fork(reviewsSaga), fork(ordersSaga), fork(adminCartsSaga), fork(userCartSaga), fork(paymentsSaga), fork(settingsSaga), fork(authSaga)]);
}

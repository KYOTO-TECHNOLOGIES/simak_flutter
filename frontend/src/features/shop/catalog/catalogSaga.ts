import { call, put, takeLatest } from "redux-saga/effects";
import { catalogApi } from "./catalogApi";
import { fetchProductsFailure, fetchProductsRequest, fetchProductsSuccess } from "./catalogSlice";
import type { Product } from "./catalogSlice";

function* fetchProductsWorker(action: ReturnType<typeof fetchProductsRequest>) {
  try {
    // if you want params later, pass action.payload
    const products: Product[] = yield call(catalogApi.listProducts, action.payload);
    yield put(fetchProductsSuccess(products));
  } catch (e: any) {
    yield put(fetchProductsFailure(e?.message || "Failed to fetch products"));
  }
}

export function* catalogSaga() {
  yield takeLatest(fetchProductsRequest.type, fetchProductsWorker);
}

import { call, put, select, takeLatest } from "redux-saga/effects";
import type { SagaIterator } from "redux-saga";
import { reviewsApi } from "./reviewsApi";
import { reviewsActions } from "./reviewsSlice";
import type { Review } from "./reviewsSlice";
import type { ReviewDto } from "./reviewsApi";
import type { RootState } from "../../../app/store";

/* ── Map backend DTO → UI Review ── */
function mapReviewDtoToReview(dto: ReviewDto): Review {
    let status: Review["status"] = "Pending";
    if (dto.is_approved === true) status = "Approved";
    else if (dto.is_approved === false) status = "Rejected";

    return {
        id: dto.id,
        productId: dto.product,
        productName: dto.product_name ?? `Product #${dto.product}`,
        userId: dto.user,
        userName: dto.user_name ?? `User #${dto.user}`,
        rating: dto.rating,
        title: dto.title ?? "",
        comment: dto.comment ?? "",
        status,
        createdAt: dto.created_at,
        updatedAt: dto.updated_at,
    };
}

/** Normalize any API shape → Review[] */
function normalizeReviews(payload: any): Review[] {
    if (Array.isArray(payload?.results)) {
        return payload.results.map(mapReviewDtoToReview);
    }
    if (Array.isArray(payload)) return payload.map(mapReviewDtoToReview);
    if (Array.isArray(payload?.data))
        return payload.data.map(mapReviewDtoToReview);
    return [];
}

function* fetchReviewsWorker(
    action: ReturnType<typeof reviewsActions.fetchReviewsRequest>
): SagaIterator {
    try {
        const auth: any = yield select((state: RootState) => (state as any).auth);
        if (auth && auth.isAuthenticated === false) {
            yield put(reviewsActions.fetchReviewsFailure("User not authenticated"));
            return;
        }

        const raw: any = yield call(reviewsApi.list, action.payload);
        const totalCount = raw?.count || 0;
        const items = normalizeReviews(raw);
        const page = action.payload?.page || 1;

        yield put(
            reviewsActions.fetchReviewsSuccess({
                items,
                totalCount,
                page,
            })
        );
    } catch (e: any) {
        console.error("Fetch Reviews Error:", {
            status: e?.response?.status,
            data: e?.response?.data,
            message: e?.message,
        });

        const errMsg =
            e?.response?.data?.detail ||
            e?.response?.data?.message ||
            e?.message ||
            "Failed to fetch reviews";

        yield put(reviewsActions.fetchReviewsFailure(errMsg));
    }
}

export function* reviewsSaga(): SagaIterator {
    yield takeLatest(
        reviewsActions.fetchReviewsRequest.type,
        fetchReviewsWorker
    );
}

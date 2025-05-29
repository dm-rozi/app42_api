module PaginationConcern
  extend ActiveSupport::Concern

  DEFAULT_LIMIT = 50

  class PaginationLimitExceeded < StandardError; end

  def pagination_params(max_limit)
    page = params[:page].to_i
    page = 1 if page < 1

    if params[:limit].present?
      limit = params[:limit].to_i

      raise PaginationLimitExceeded, "Limit cannot exceed #{max_limit}" if limit > max_limit

      limit = DEFAULT_LIMIT if limit <= 0
    else
      limit = DEFAULT_LIMIT
    end

    { page:, limit: }
  end

  def paginate_with_next_page(scope, max_limit = DEFAULT_LIMIT)
    page_info = pagination_params(max_limit)

    page = page_info[:page]
    limit = page_info[:limit]
    offset = (page - 1) * limit

    results = scope.limit(limit + 1).offset(offset).to_a
    has_next_page = results.size > limit
    results = results.first(limit)

    [ results, page, results.size, has_next_page ]
  end
end

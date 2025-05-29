module Api
  module V1
    class PostsController < ApplicationController
      include PaginationConcern

      MAX_TOP_POSTS_PAGE_LIMIT = 250
      MAX_SHARED_IPS_PAGE_LIMIT = 100

      rescue_from PaginationLimitExceeded do |e|
        render json: { errors: [ e.message ] }, status: :bad_request
      end

      def create
        user = User.find_or_initialize_by(login: post_params[:login])

        if user.new_record?
          unless user.save
            return render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        post = user.posts.build(
          title: post_params[:title],
          body: post_params[:body],
          ip: post_params[:ip] || request.remote_ip.presence
        )

        if post.save
          render json: {
            data: {
              post: post.attributes,
              user: user.attributes
            }
          }, status: :created
        else
          render json: { errors: post.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def top
        scope = Post
                  .select("posts.id, posts.title, posts.body, AVG(ratings.value) AS average_rating")
                  .joins(:ratings)
                  .group("posts.id")
                  .order("average_rating DESC")

        posts, page, limit, has_next_page = paginate_with_next_page(scope, MAX_TOP_POSTS_PAGE_LIMIT)

        render json: {
          data: posts.map { |p| p.slice("id", "title", "body") },
          page_info: { page:, limit:, has_next_page: }
        }
      end

      def shared_ips
        scope = Post
                  .joins(:user)
                  .group(:ip)
                  .having("COUNT(DISTINCT posts.user_id) > 1")
                  .select(:ip, Arel.sql("ARRAY_AGG(DISTINCT users.login) AS logins"))

        rows, page, limit, has_next_page = paginate_with_next_page(scope, MAX_SHARED_IPS_PAGE_LIMIT)

        render json: {
          data: rows.map { |row| { ip: row.ip, logins: row.logins } },
          page_info: { page:, limit:, has_next_page: }
        }
      end

      private

      def post_params
        params.permit(:login, :title, :body, :ip)
      end
    end
  end
end

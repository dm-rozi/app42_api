# spec/concerns/pagination_concern_spec.rb
require 'rails_helper'

RSpec.describe PaginationConcern do
  let(:sample_class) do
    Class.new do
      include PaginationConcern
      attr_accessor :params
    end
  end

  let(:paginator) { sample_class.new }

  describe '#pagination_params' do
    context 'when no params are provided' do
      it 'returns default page and limit' do
        paginator.params = {}
        result = paginator.pagination_params(100)
        expect(result).to eq({ page: 1, limit: 50 })
      end
    end

    context 'when page is invalid' do
      it 'defaults to page 1' do
        paginator.params = { page: '0', limit: '10' }
        result = paginator.pagination_params(100)
        expect(result[:page]).to eq(1)
      end
    end

    context 'when limit exceeds max_limit' do
      it 'raises PaginationLimitExceeded' do
        paginator.params = { limit: '999' }
        expect {
          paginator.pagination_params(100)
        }.to raise_error(PaginationConcern::PaginationLimitExceeded, /Limit cannot exceed/)
      end
    end

    context 'when limit is negative' do
      it 'defaults to DEFAULT_LIMIT' do
        paginator.params = { limit: '-1' }
        result = paginator.pagination_params(100)
        expect(result[:limit]).to eq(50)
      end
    end

    context 'when valid params provided' do
      it 'returns them as is' do
        paginator.params = { page: '2', limit: '20' }
        result = paginator.pagination_params(100)
        expect(result).to eq({ page: 2, limit: 20 })
      end
    end
  end

  describe '#paginate_with_next_page' do
    before do
      user = User.create!(login: "tester")
      30.times do |i|
        Post.create!(
          title: "Post #{i}",
          body: "Body #{i}",
          ip: "127.0.0.#{i % 5}",
          user: user
        )
      end
    end

    it 'returns correct slice and next_page true if there is more' do
      paginator.params = { page: '1', limit: '10' }
      scope = Post.order(:id)

      results, page, count, has_next_page = paginator.paginate_with_next_page(scope, 20)

      expect(results.size).to eq(10)
      expect(page).to eq(1)
      expect(count).to eq(10)
      expect(has_next_page).to eq(true)
    end

    it 'returns next_page false when no more results' do
      paginator.params = { page: '3', limit: '10' }
      scope = Post.order(:id)

      results, page, count, has_next_page = paginator.paginate_with_next_page(scope, 20)

      expect(results.size).to eq(10)
      expect(page).to eq(3)
      expect(count).to eq(10)
      expect(has_next_page).to eq(false)
    end
  end
end

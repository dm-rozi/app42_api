.PHONY: all seed puma stop_puma

PUMA_PID_FILE := tmp/pids/puma_seeder.pid

db_seed: puma wait seed stop_puma

puma:
	@echo "🚀 Starting Puma..."
	@mkdir -p tmp/pids
	@WEB_CONCURRENCY=8 RAILS_MAX_THREADS=10 bundle exec puma -C config/puma.rb --pidfile $(PUMA_PID_FILE) &
	@sleep 1

wait:
	@echo "⏳ Waiting for Puma to boot..."
	@timeout 10 bash -c 'until curl -s http://localhost:3000 >/dev/null; do sleep 0.2; done' || (echo "❌ Puma did not start" && $(MAKE) stop_puma && exit 1)

seed:
	@echo "🌱 Running seeds..."
	@bundle exec rails db:seed || (echo "❌ Seed failed!" && $(MAKE) stop_puma && exit 1)

stop_puma:
	@echo "🛑 Stopping Puma..."
	@if [ -f $(PUMA_PID_FILE) ]; then \
		kill -TERM `cat $(PUMA_PID_FILE)` && rm -f $(PUMA_PID_FILE); \
	else \
		echo "⚠️ No Puma PID file found."; \
	fi

check: lint test

test:
	@echo "Running RSpec tests..."
	@bundle exec rspec

lint:
	@echo "Running RuboCop..."
	@bundle exec rubocop
module BenchmarkHelper
  def average_benchmark(n=10, &block)
    avg = 0
    n.times do
      avg += Benchmark.measure{yield}.real
    end
    avg / n
  end
end

#include <chrono>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>

#include "ByteBlockBackedDictionary.h"

namespace {

std::string GenerateLargeTestData(int multiplier) {
  std::stringstream sst;
  constexpr int keys = 1024;
  constexpr int values = 128;

  for (int m = 0; m < multiplier; ++m) {
    for (int k = 0; k < keys; ++k) {
      int nSpace = k / 128 + 1;
      std::string space(nSpace, ' ');

      // Emulate real typical key-value format
      std::string keyString = "first_" + std::to_string(k) + space;
      for (int v = 0; v < values; ++v) {
        sst << keyString;
        sst << "second_" << v;
        sst << "\n";
      }

      if ((k % 16) == 0) {
        sst << space << "# comment_" << k << "\n";
      }
    }
  }
  return sst.str();
}

void WriteTestDataToFile(const std::string& filename, const std::string& data) {
  std::ofstream out(filename, std::ios::binary);
  out.write(data.data(), data.size());
}

std::string ReadFileIntoString(const std::string& filename) {
  std::ifstream in(filename, std::ios::binary | std::ios::ate);
  if (!in) {
    return "";
  }
  std::streamsize size = in.tellg();
  in.seekg(0, std::ios::beg);
  std::string buffer(size, '\0');
  if (in.read(&buffer[0], size)) {
    return buffer;
  }
  return "";
}

}  // namespace

int main() {
  std::cout << "Generating test data...\n";
  // Generate about ~100MB data
  // multiplier = 34 => ~100MB, just a magic number selected by testing XD
  std::string testData = GenerateLargeTestData(34);

  double dataSizeGB =
      static_cast<double>(testData.size()) / (1024.0 * 1024.0 * 1024.0);
  double dataSizeMB = static_cast<double>(testData.size()) / (1024.0 * 1024.0);

  std::cout << "Test data size: " << std::fixed << std::setprecision(2)
            << dataSizeMB << " MB (" << testData.size() << " bytes)\n";

  std::string filename = "test_dictionary_data_throughput.txt";
  WriteTestDataToFile(filename, testData);

  std::cout << "---------------------------------------------------------\n";

  // Measure File I/O + Parsing Combined
  {
    auto start = std::chrono::high_resolution_clock::now();

    std::string fileContent = ReadFileIntoString(filename);
    McBopomofo::ByteBlockBackedDictionary dictionary;
    dictionary.parse(fileContent.c_str(), fileContent.size());

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed = end - start;

    std::cout << "[1] File I/O + Parsing (End-to-end)\n";
    std::cout << "    Time elapsed : " << elapsed.count() << " seconds\n";
    std::cout << "    Throughput   : " << (dataSizeMB / elapsed.count())
              << " MB/s\n";
    std::cout << "    Throughput   : " << (dataSizeGB / elapsed.count())
              << " GB/s\n";
    std::cout << "---------------------------------------------------------\n";
  }

  // Measure Pure Parsing (data already in memory)
  {
    auto start = std::chrono::high_resolution_clock::now();

    McBopomofo::ByteBlockBackedDictionary dictionary;
    dictionary.parse(testData.c_str(), testData.size());

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed = end - start;

    std::cout << "[2] Pure Parsing (In-Memory Data)\n";
    std::cout << "    Time elapsed : " << elapsed.count() << " seconds\n";
    std::cout << "    Throughput   : " << (dataSizeMB / elapsed.count())
              << " MB/s\n";
    std::cout << "    Throughput   : " << (dataSizeGB / elapsed.count())
              << " GB/s\n";
    std::cout << "---------------------------------------------------------\n";
  }

  // Measure Value-Then-Key Parsing (data already in memory)
  {
    auto start = std::chrono::high_resolution_clock::now();

    McBopomofo::ByteBlockBackedDictionary dictionary;
    dictionary.parse(
        testData.c_str(), testData.size(),
        McBopomofo::ByteBlockBackedDictionary::ColumnOrder::VALUE_THEN_KEY);

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed = end - start;

    std::cout << "[3] Value-Then-Key Parsing (In-Memory Data)\n";
    std::cout << "    Time elapsed : " << elapsed.count() << " seconds\n";
    std::cout << "    Throughput   : " << (dataSizeMB / elapsed.count())
              << " MB/s\n";
    std::cout << "    Throughput   : " << (dataSizeGB / elapsed.count())
              << " GB/s\n";
    std::cout << "---------------------------------------------------------\n";
  }

  // Cleanup
  // std::remove(filename.c_str());

  return 0;
}

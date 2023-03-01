package service;

import java.util.List;

public interface TableService {
    List<List<String>> getTableContent(String molecule);
}

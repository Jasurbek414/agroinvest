package uz.agroinvest.common.util;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@Converter
public class JsonListConverter implements AttributeConverter<List<String>, String> {

    private static final Logger logger = LoggerFactory.getLogger(JsonListConverter.class);
    private static final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public String convertToDatabaseColumn(List<String> attribute) {
        if (attribute == null) {
            return "[]";
        }
        try {
            return objectMapper.writeValueAsString(attribute);
        } catch (JsonProcessingException e) {
            logger.error("Error converting List<String> to JSON string", e);
            return "[]";
        }
    }

    @Override
    @SuppressWarnings("unchecked")
    public List<String> convertToEntityAttribute(String dbData) {
        if (dbData == null || dbData.isBlank()) {
            return new ArrayList<>();
        }
        try {
            return objectMapper.readValue(dbData, List.class);
        } catch (IOException e) {
            logger.error("Error converting JSON string to List<String>", e);
            return new ArrayList<>();
        }
    }
}

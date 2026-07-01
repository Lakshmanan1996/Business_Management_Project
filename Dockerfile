# =========================================================
#  Java + Maven – Multi Stage (Recommended)
# =========================================================
# Build stage
FROM maven:3.9.6-eclipse-temurin-17 AS build

WORKDIR /app
COPY pom.xml .

# Download dependencies
RUN mvn dependency:go-offline

COPY . .

RUN mvn clean package -DskipTests



# Runtime stage
FROM eclipse-temurin:17-jdk-jammy

WORKDIR /app
COPY --from=build /app/target/*.jar app.jar

EXPOSE 2330

CMD ["java", "-jar", "app.jar"]
